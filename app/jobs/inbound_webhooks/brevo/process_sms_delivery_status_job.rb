module InboundWebhooks
  module Brevo
    class ProcessSmsDeliveryStatusJob < ProcessDeliveryStatusJobBase
      private

      def assign_delivery_status_and_date
        InboundWebhooks::Brevo::AssignSmsDeliveryStatusAndDate.call(webhook_params: @webhook_params,
                                                                    record: @record)
      end
    end
  end
end
