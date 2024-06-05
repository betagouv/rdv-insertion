class BrevoMailWebhooksController < ApplicationController
  skip_before_action :authenticate_agent!, :verify_authenticity_token

  PERMITTED_PARAMS = %i[
    email
    event
    date
  ].freeze

  def create
    # On utilise le même compte Brevo et les mêmes définitions de webhooks sur staging et production
    # On ne veut pas que les webhooks de staging soient traités en production et inversement
    # On défini l'environnement dans le headers["X-Mailin-custom"] du mail envoyé par Brevo
    return if (environment != Rails.env) || params[:"X-Mailin-custom"].blank?

    Invitations::AssignDeliveryStatusAndDate.call(brevo_webhook_params: brevo_webhook_params,
                                                  invitation_id: invitation_id)
  end

  private

  def environment
    JSON.parse(params[:"X-Mailin-custom"])["environment"]
  end

  def invitation_id
    JSON.parse(params[:"X-Mailin-custom"])["invitation_id"]
  end

  def brevo_webhook_params
    params.permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end
end
