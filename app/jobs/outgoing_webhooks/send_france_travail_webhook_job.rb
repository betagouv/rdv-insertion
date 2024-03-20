module OutgoingWebhooks
  class SendFranceTravailWebhookJob < ApplicationJob
    def perform(payload, timestamp)
      call_service!(
        OutgoingWebhooks::SendFranceTravailWebhook,
        payload:, timestamp:
      )
    end
  end
end
