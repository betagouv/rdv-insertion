class FollowUp < ApplicationRecord
  include FollowUpStatus
  include Invitable
  include Notificable
  include HasParticipationsToRdvs

  belongs_to :user
  belongs_to :motif_category
  has_many :invitations, dependent: :destroy
  has_many :participations, dependent: :nullify

  has_many :rdvs, through: :participations
  has_many :notifications, through: :participations

  validates :user, uniqueness: { scope: :motif_category,
                                 message: "est déjà suivi pour cette catégorie de motif" }

  delegate :name, :short_name, to: :motif_category, prefix: true

  STATUSES_WITH_ACTION_REQUIRED = %w[
    rdv_needs_status_update rdv_noshow rdv_revoked rdv_excused multiple_rdvs_cancelled
  ].freeze
  CONVOCABLE_STATUSES = %w[
    rdv_noshow rdv_excused multiple_rdvs_cancelled
  ].freeze

  scope :status, ->(status) { where(status: status) }
  scope :action_required, lambda { |number_of_days_before_action_required|
    status(STATUSES_WITH_ACTION_REQUIRED)
      .or(invitation_pending.invited_before_time_window(number_of_days_before_action_required))
  }
  scope :invited_before_time_window, lambda { |number_of_days_before_action_required|
    where.not(
      id: joins(:invitations).where("invitations.created_at > ?", number_of_days_before_action_required.days.ago)
                             .where(invitations: { reminder: false })
                             .pluck(:follow_up_id)
    )
  }
  scope :with_sent_invitations, -> { where.associated(:invitations) }
  scope :orientation, -> { joins(:motif_category).where(motif_category: { leads_to_orientation: true }) }

  def action_required_status?
    status.in?(STATUSES_WITH_ACTION_REQUIRED)
  end

  def convocable_status?
    status.in?(CONVOCABLE_STATUSES)
  end

  def time_to_accept_invitation_exceeded?(number_of_days_before_action_required)
    invitation_pending? && invited_before_time_window?(number_of_days_before_action_required)
  end

  def time_between_invitation_and_rdv_in_days
    first_participation_creation_date.to_datetime.mjd - first_invitation_created_at.to_datetime.mjd
  end

  def closed?
    closed_at.present?
  end

  def orientation?
    motif_category.leads_to_orientation?
  end

  def human_status
    I18n.t("activerecord.attributes.follow_up.statuses.#{status}")
  end
end
