class SendTransactionalSms < BaseService
  def initialize(phone_number:, sender_name:, content:)
    @sender_name = sender_name
    @phone_number = phone_number
    @content = content
  end

  def call
    send_transactional_sms
  end

  private

  def send_transactional_sms
    api_instance = SibApiV3Sdk::TransactionalSMSApi.new
    api_instance.send_transac_sms(transactional_sms)
  rescue SibApiV3Sdk::ApiError => e
    Sentry.capture_exception(
      e,
      extra: {
        response_body: e.response_body,
        phone_number: @phone_number,
        content: formatted_content
      }
    )
    fail!("une erreur est survenue en envoyant le sms. #{e.message}")
  end

  def transactional_sms
    # Pour la mise en place des webhooks brevo sur les sms transactionnels il va falloir ajouter un champ webUrl dans
    # le body de la requête avec l'id de l'invitation pour retrouver l'invitation à la reception du webhook

    SibApiV3Sdk::SendTransacSms.new(
      sender: @sender_name,
      recipient: @phone_number,
      content: formatted_content,
      type: "transactional",
      webUrl: "#{ENV['HOST']}/brevo_sms_webhooks/invitation_id_1234567"
    )
  end

  def formatted_content
    @content.tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
  end
end
