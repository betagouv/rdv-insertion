module InboundWebhooks
  module Brevo
    class AssignDeliveryStatusAndDateBase < BaseService
      def initialize(webhook_params:, record:)
        @webhook_params = webhook_params.deep_symbolize_keys
        @record = record
      end

      def call
        return if @record.delivery_status.in?(record_class::FINAL_DELIVERY_STATUS)
        return if old_update?
        return if webhook_mismatch?

        @record.delivery_status = delivery_status
        @record.delivered_at = @webhook_params[:date]
        save_record!(@record)
      end

      private

      def old_update?
        return false if @record.delivered_at.blank?

        @record.delivered_at.to_datetime > @webhook_params[:date].to_datetime
      end

      def record_class
        @record_class ||= @record.class
      end

      def webhook_mismatch?
        raise NoMethodError
      end

      def delivery_status
        raise NoMethodError
      end
    end
  end
end
