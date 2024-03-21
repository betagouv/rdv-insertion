class Notification < ApplicationRecord
  include HasCurrentCategoryConfiguration
  include Templatable
  include Sendable

  attr_accessor :content

  belongs_to :participation, optional: true

  enum event: {
    participation_created: 0, participation_updated: 1, participation_cancelled: 2, participation_reminder: 3
  }
  enum format: { sms: 0, email: 1, postal: 2 }, _prefix: true

  validates :format, :event, :rdv_solidarites_rdv_id, presence: true

  delegate :department, :user, :rdv, :motif_category, :instruction_for_rdv, :rdv_context, to: :participation
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
