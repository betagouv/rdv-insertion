class Participation < ApplicationRecord
  include Notificable
  include HasCurrentCategoryConfiguration
  include RdvParticipationStatus

  belongs_to :rdv
  belongs_to :follow_up
  belongs_to :user
  belongs_to :agent_prescripteur,
             class_name: "Agent",
             primary_key: "rdv_solidarites_agent_id",
             foreign_key: "rdv_solidarites_agent_prescripteur_id",
             optional: true

  has_many :notifications, dependent: :nullify
  has_many :follow_up_invitations, through: :follow_up, source: :invitations

  has_one :organisation, through: :rdv

  has_many :category_configurations, through: :organisation

  validates :status, presence: true
  validates :rdv_solidarites_participation_id, uniqueness: true, allow_nil: true

  after_commit :refresh_follow_up_status
  after_commit :notify_user, if: :should_notify?, on: [:create, :update]
  after_commit :notify_external, on: [:create, :update, :destroy]

  enum created_by: { agent: "agent", user: "user", prescripteur: "prescripteur" }, _prefix: :created_by

  delegate :starts_at, :motif_name,
           :rdv_solidarites_url, :rdv_solidarites_rdv_id, :instruction_for_rdv,
           to: :rdv
  delegate :department, :department_id, to: :organisation
  delegate :phone_number_is_mobile?, :email?, to: :user
  delegate :motif_category, :orientation?, to: :follow_up

  def notifiable?
    convocable? && in_the_future? && status.in?(%w[unknown revoked])
  end

  private

  def refresh_follow_up_status
    RefreshFollowUpStatusesJob.perform_async(follow_up_id)
  end

  def status_reloaded_from_cancelled?
    status_previously_was.in?(CANCELLED_STATUSES) && status.in?(%w[unknown])
  end

  def participation_just_cancelled?
    # Do not notify users for a cancelled event for a previously cancelled participation
    status.in?(CANCELLED_STATUSES) && !status_previously_was.in?(CANCELLED_STATUSES)
  end

  def should_notify?
    notifiable? && event_to_notify
  end

  def notify_user
    if phone_number_is_mobile?
      NotifyParticipationToUserJob.perform_async(id, "sms",
                                                 "participation_#{event_to_notify}")
    end
    NotifyParticipationToUserJob.perform_async(id, "email", "participation_#{event_to_notify}") if email?
  end

  def notify_external
    NotifyParticipationToExternalOrganisationEmailJob.perform_async(
      id,
      event_to_notify || :updated
    )
  end

  def event_to_notify
    if id_previously_changed? || status_reloaded_from_cancelled?
      :created
    elsif participation_just_cancelled?
      :cancelled
    end
  end
end
