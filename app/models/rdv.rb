class Rdv < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [
    :address, :cancelled_at, :context, :created_by, :duration_in_min, :starts_at, :status, :uuid,
    :users_count, :max_participants_count
  ].freeze

  include Notificable
  include RdvParticipationStatus
  include WebhookDeliverable

  after_commit :notify_participations, on: :update, if: :should_notify?
  after_commit :refresh_follow_up_statuses, on: [:create, :update]

  belongs_to :organisation
  belongs_to :motif
  belongs_to :lieu, optional: true

  has_many :participations, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy

  has_many :notifications, through: :participations
  has_many :follow_ups, through: :participations
  has_many :agents, through: :agents_rdvs
  has_many :users, through: :participations
  has_many :webhook_endpoints, through: :organisation

  # Needed to build participations in process_rdv_job
  accepts_nested_attributes_for :participations, allow_destroy: true, reject_if: :new_participation_already_created?

  validates :starts_at, :duration_in_min, presence: true
  validates :rdv_solidarites_rdv_id, uniqueness: true, allow_nil: true

  validate :follow_ups_motif_categories_are_uniq

  enum created_by: { agent: 0, user: 1, file_attente: 2, prescripteur: 3 }, _prefix: :created_by

  delegate :presential?, :by_phone?, :collectif?, to: :motif
  delegate :department, :rdv_solidarites_organisation_id, to: :organisation
  delegate :name, to: :motif, prefix: true
  delegate :instruction_for_rdv, to: :motif

  scope :with_lieu, -> { where.not(lieu_id: nil) }
  scope :future, -> { where("starts_at > ?", Time.zone.now) }
  scope :collectif, -> { joins(:motif).merge(Motif.collectif) }
  scope :with_remaining_seats, -> { where("users_count < max_participants_count OR max_participants_count IS NULL") }
  scope :collectif_and_available_for_reservation, -> { collectif.with_remaining_seats.future.not_revoked }

  def self.jwt_payload_keys = [:id, :address, :starts_at]

  def self.latest
    all.to_a.max_by(&:starts_at)
  end

  def rdv_solidarites_url
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/" \
      "#{organisation.rdv_solidarites_organisation_id}/rdvs/#{rdv_solidarites_rdv_id}"
  end

  def formatted_start_date
    starts_at.to_datetime.strftime("%d/%m/%Y")
  end

  def formatted_start_time
    starts_at.to_datetime.strftime("%H:%M")
  end

  def phone_number
    return lieu.phone_number if lieu&.phone_number.present?

    organisation.phone_number
  end

  def participation_for(user)
    participations.find { |p| p.user_id == user.id }
  end

  def add_user_url(rdv_solidarites_user_id)
    params = { add_user: [rdv_solidarites_user_id] }
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/#{rdv_solidarites_organisation_id}/rdvs/" \
      "#{rdv_solidarites_rdv_id}/edit?#{params.to_query}"
  end

  private

  def refresh_follow_up_statuses
    RefreshFollowUpStatusesJob.perform_async(follow_up_ids)
  end

  def notify_participations
    NotifyParticipationsJob.perform_async(notifiable_participations.map(&:id), :updated)
  end

  def should_notify?
    in_the_future? && notifiable_participations.any? && reason_to_notify?
  end

  def reason_to_notify?
    address_previously_changed? || starts_at_previously_changed?
  end

  def notifiable_participations
    participations.select(&:notifiable?)
  end

  def follow_ups_motif_categories_are_uniq
    return if follow_ups.map(&:motif_category).uniq.length < 2

    errors.add(:base, "Un RDV ne peut pas être lié à deux catégories de motifs différents")
  end

  def new_participation_already_created?(participation_attributes)
    participation_attributes.deep_symbolize_keys[:id].nil? &&
      participation_attributes.deep_symbolize_keys[:rdv_solidarites_participation_id]&.to_i.in?(
        participations.map(&:rdv_solidarites_participation_id)
      )
  end
end
