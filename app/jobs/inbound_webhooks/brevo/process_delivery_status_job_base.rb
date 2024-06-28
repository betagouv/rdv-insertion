module InboundWebhooks
  module Brevo
    class ProcessDeliveryStatusJobBase < ApplicationJob
      def perform(webhook_params, record_identifier)
        @webhook_params = webhook_params
        @record_identifier = record_identifier

        return unless record_present?

        assign_delivery_status_and_date
      end

      private

      def assign_delivery_status_and_date
        raise NoMethodError
      end

      def record
        # record_identifier : notification_123 or invitation_123
        @record ||= record_class.find_by(id: record_id)
      end

      def record_class
        @record_class ||= @record_identifier.split("_").first.classify.constantize
      end

      def record_id
        @record_id ||= @record_identifier.split("_").last
      end

      def record_present?
        return true if record.present?

        Sentry.capture_message("#{record_class} not found", extra: { webhook_params: @webhook_params })
        false
      end
    end
  end
end
