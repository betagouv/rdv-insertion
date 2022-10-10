module Sendable
  extend ActiveSupport::Concern

  included do
    delegate :email, :phone_number, :phone_number_formatted, :phone_number_is_mobile?,
             to: :applicant
    delegate :signature_lines, to: :messages_configuration, allow_nil: true
  end

  def sms_sender_name
    messages_configuration&.sms_sender_name || "Dept#{applicant.department_number}"
  end
end
