class Notification < ApplicationRecord
  include HasCurrentCategoryConfiguration
  include Templatable
  include Sendable
  include Deliverable

  attr_accessor :content

  belongs_to :participation, optional: true

  enum event: {
    participation_created: "participation_created",
    participation_updated: "participation_updated",
    participation_cancelled: "participation_cancelled",
    participation_reminder: "participation_reminder"
  }
  enum format: { sms: "sms", email: "email", postal: "postal" }, _prefix: true

  validates :format, :event, :rdv_solidarites_rdv_id, presence: true

  delegate :department, :user, :rdv, :motif_category, :instruction_for_rdv, :follow_up, to: :participation
  delegate :organisation, to: :rdv, allow_nil: true
  delegate :messages_configuration, :category_configurations, to: :organisation

  def send_to_user
    case format
    when "sms"
      Notifications::SendSms.call(notification: self)
    when "email"
      Notifications::SendEmail.call(notification: self)
    when "postal"
      Notifications::GenerateLetter.call(notification: self)
    end
  end
end
