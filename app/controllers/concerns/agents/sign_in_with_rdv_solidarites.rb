class RdvSolidarites::InvalidCredentialsError < StandardError; end

module Agents::SignInWithRdvSolidarites
  extend ActiveSupport::Concern

  included do
    rescue_from RdvSolidarites::InvalidCredentialsError, with: :invalid_credentials
  end

  private

  def validate_rdv_solidarites_credentials!
    raise RdvSolidarites::InvalidCredentialsError unless rdv_solidarites_credentials.valid?
  end

  def rdv_solidarites_credentials
    @rdv_solidarites_credentials ||= RdvSolidaritesCredentials.new(
      uid: request.headers["uid"],
      client: request.headers["client"],
      access_token: request.headers["access-token"]
    )
  end

  def invalid_credentials
    render(
      json: { errors: ["Les identifiants de session RDV-Solidarités sont invalides"] },
      status: :unauthorized
    )
  end

  def retrieve_agent!
    return if authenticated_agent

    render json: { success: false, errors: ["L'agent ne fait pas partie d'une organisation sur RDV-Insertion"] },
           status: :forbidden
  end

  def mark_agent_as_logged_in!
    return if authenticated_agent.update(last_sign_in_at: Time.zone.now)

    render json: { success: false, errors: authenticated_agent.errors.full_messages }, status: :unprocessable_entity
  end

  def authenticated_agent
    @authenticated_agent ||= Agent.find_by(email: rdv_solidarites_credentials.uid)
  end
end
