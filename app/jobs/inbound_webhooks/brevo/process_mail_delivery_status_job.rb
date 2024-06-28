module InboundWebhooks
  module Brevo
    class ProcessMailDeliveryStatusJob < ProcessDeliveryStatusJobBase
      private

      def assign_delivery_status_and_date
        InboundWebhooks::Brevo::AssignMailDeliveryStatusAndDate.call(webhook_params: @webhook_params,
                                                                     record: @record)
      end
    end
  end
end
