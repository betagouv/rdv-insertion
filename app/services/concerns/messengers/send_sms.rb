module Messengers::SendSms
  private

  def verify_format!(sendable)
    fail!("Envoi de SMS alors que le format est #{sendable.format}") unless sendable.format == "sms"
  end

  def verify_phone_number!(sendable)
    fail!("Le téléphone doit être renseigné") if sendable.phone_number.blank?
    fail!("Le numéro de téléphone doit être un mobile") unless sendable.phone_number_is_mobile?
  end

  def send_sms(sms_sender_name, phone_number_formatted, content)
    return Rails.logger.info(content) if Rails.env.development? || Rails.env.test?

    SendTransactionalSms.call(phone_number_formatted: phone_number_formatted,
                              sender_name: sms_sender_name, content: content)
  end
end
