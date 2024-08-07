unless Rails.env.test?
  AgentConnect.initialize! do |config|
    config.client_id = ENV["AGENT_CONNECT_CLIENT_ID"]
    config.client_secret = ENV["AGENT_CONNECT_CLIENT_SECRET"]
    config.scope = "openid email"
    config.base_url = ENV["AGENT_CONNECT_BASE_URL"]
    config.algorithm = "RS256"

    config.success_callback = lambda do |user_info|
      agent = Agent.find_by(email: user_info.user_email)

      if agent && agent.update(last_sign_in_at: Time.zone.now)
        timestamp = Time.zone.now.to_i
        session[:agent_auth] = {
          id: agent.id,
          origin: "agent_connect",
          signature: agent.sign_with(timestamp),
          created_at: timestamp,
          agent_connect_id_token: user_info.id_token_for_logout
        }
        redirect_to session[:agent_return_to] || Rails.application.routes.url_helpers.root_path
      else
        flash[:error] = "Il n'y a pas de compte agent pour l'adresse mail #{user_info.user_email}.
          Vous devez utiliser Agent Connect avec l'adresse mail à laquelle vous avez reçu votre invitation"
        redirect_to Rails.application.routes.url_helpers.sign_in_path
      end
    end

    config.error_callback = lambda do |_|
      flash[:error] = "Nous n'avons pas pu vous connecter. Veuillez réessayer."
      redirect_to Rails.application.routes.url_helpers.sign_in_path
    end
  end
end
