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
    # L'id de l'invitation est un tag qui permet de suivre les envois de sms via l'API Sendinblue
    # Il n'y a pas de webhook, il faudra donc aller chercher les informations
    # opts = { tag: "invitation_id_1234" }
    # api_instance.get_transac_aggregated_sms_report(opts)
    # #<SibApiV3Sdk::GetTransacAggregatedSmsReport:0x000000014d23caa0
    #  @accepted=1,
    #  @blocked=0,
    #  @delivered=1, <- 1 sms envoyé et bien reçu
    #  @hard_bounces=0,
    #  @range="2024-04-25|2024-04-25",
    #  @rejected=0,
    #  @replied=0,
    #  @requests=1,
    #  @soft_bounces=0,
    #  @unsubscribed=0>
    SibApiV3Sdk::SendTransacSms.new(
      sender: @sender_name,
      recipient: @phone_number,
      content: formatted_content,
      type: "transactional",
      tag: "invitation_id_1234"
    )
  end

  def formatted_content
    @content.tr("áâãëẽêíïîĩóôõúûũçÀÁÂÃÈËẼÊÌÍÏÎĨÒÓÔÕÙÚÛŨ", "aaaeeeiiiiooouuucAAAAEEEEIIIIIOOOOUUUU")
  end
end
