module Messengers::SendSms
  private

  def verify_format!(sendable)
    fail!("Envoi de SMS alors que le format est #{sendable.format}") unless sendable.format == "sms"
  end

  def verify_phone_number!(sendable)
    fail!("Le téléphone doit être renseigné") if sendable.phone_number.blank?
    fail!("Le numéro de téléphone doit être un mobile") unless sendable.phone_number_is_mobile?
  end

  def send_sms(sms_sender_name, phone_number, content, record_identifier)
    return Rails.logger.info(content) if Rails.env.development?

    SendTransactionalSms.call(phone_number: phone_number,
                              sender_name: sms_sender_name, content: content, record_identifier: record_identifier)
  end
end
