module Brevo
  class MailWebhooksController < ApplicationController
    skip_before_action :authenticate_agent!, :verify_authenticity_token

    PERMITTED_PARAMS = %i[
      email
      event
      date
    ].freeze

    def create
      return if params[:"X-Mailin-custom"].nil?

      InboundWebhooks::Brevo::ProcessMailDeliveryStatusJob.perform_async(brevo_webhook_params, record_identifier)
    end

    private

    def record_identifier
      JSON.parse(params[:"X-Mailin-custom"])["record_identifier"]
    end

    def brevo_webhook_params
      params.permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
    end
  end
end
