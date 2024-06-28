class SendTransactionalSms < BaseService
  def initialize(phone_number:, sender_name:, content:, record_identifier:)
    @sender_name = sender_name
    @phone_number = phone_number
    @content = content
    @record_identifier = record_identifier
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
    opts = {
      sender: @sender_name,
      recipient: @phone_number,
      content: formatted_content,
      type: "transactional",
      webUrl: Rails.application.routes.url_helpers.brevo_sms_webhooks_url(@record_identifier, host: ENV["HOST"])
    }

    SibApiV3Sdk::SendTransacSms.new(**opts)
  end

  def formatted_content
    @content.tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
  end
end
