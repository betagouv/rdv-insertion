module OutgoingWebhooks
  class SendFranceTravailWebhook < BaseService
    def initialize(payload:, timestamp:)
      @payload = payload
      @timestamp = timestamp
    end

    def call
      return if france_travail_rdv_api_url.blank?

      Rdv.with_advisory_lock("france_travail_webhook_#{resource_id}") do
        return if old_update?

        send_request!
        create_webhook_receipt
      end
    end

    private

    def resource_id = @payload["idOrigine"]

    def create_webhook_receipt
      webhook_receipt = WebhookReceipt.new(resource_model: "Rdv", resource_id:, timestamp: @timestamp)
      return if webhook_receipt.save

      Sentry.capture_message("Webhook receipt with attributes #{webhook_receipt.attributes} could not be created.")
    end

    def old_update?
      last_webhook_receipt_for_resource.present? && @timestamp <= last_webhook_receipt_for_resource.timestamp
    end

    def last_webhook_receipt_for_resource
      WebhookReceipt.france_travail.where(resource_id:).order(timestamp: :desc).first
    end

    def send_request!
      response = Faraday.post(
        france_travail_rdv_api_url,
        @payload.to_json,
        request_headers
      )
      return if response.success?

      fail!(
        "Impossible d'appeler l'endpoint de rdv FT.\n" \
        "Status: #{response.status}\n Body: #{response.body}"
      )
    end

    def france_travail_rdv_api_url = ENV["FRANCE_TRAVAIL_RDV_API_URL"]

    def request_headers
      {
        "Authorization" => "Bearer #{france_travail_access_token}",
        "Content-Type" => "application/json"
      }
    end

    def retrieve_france_travail_access_token
      @retrieve_france_travail_access_token ||= call_service!(RetrieveFranceTravailAccessToken)
    end

    def france_travail_access_token
      retrieve_france_travail_access_token.access_token
    end
  end
end
