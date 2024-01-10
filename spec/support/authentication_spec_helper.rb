module AuthenticationSpecHelper
  def sign_in(agent)
    setup_request_session(agent)
    mock_rdv_solidarites_session(agent.email)
  end

  def session_hash(agent_email)
    { "client" => "someclient", "uid" => agent_email, "access_token" => "sometoken" }.symbolize_keys
  end

  def setup_request_session(agent)
    request.session["agent_id"] = agent.id
    request.session["rdv_solidarites"] = session_hash(agent.email)
  end

  def setup_agent_session(agent)
    page.set_rack_session(agent_id: agent.id, rdv_solidarites: session_hash(agent.email))

    stub_request(:get, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/auth/validate_token")
      .with(headers: { "Content-Type" => "application/json" }.merge(session_hash(agent.email)))
      .to_return(body: { "data" => { "uid" => agent.email } }.to_json)
  end

  def mock_rdv_solidarites_session(agent_email)
    allow(RdvSolidaritesSessionFactory).to receive(:create_with)
      .with(**session_hash(agent_email))
      .and_return(rdv_solidarites_session)
    allow(rdv_solidarites_session).to receive_messages(valid?: true, uid: agent_email, to_h: session_hash(agent_email))
  end

  def rdv_solidarites_session
    @rdv_solidarites_session ||= instance_double(RdvSolidaritesSession::WithAccessToken)
  end
end
