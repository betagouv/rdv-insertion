module InboundWebhooks
  module Brevo
    class AssignMailDeliveryStatusAndDate < AssignDeliveryStatusAndDateBase
      private

      def delivery_status
        @delivery_status ||= @webhook_params[:event]
      end

      def webhook_mismatch?
        return false if @record.email == @webhook_params[:email]

        Sentry.capture_message("#{record_class} email and webhook email does not match",
                               extra: { record: @record, webhook: @webhook_params })
        true
      end
    end
  end
end
