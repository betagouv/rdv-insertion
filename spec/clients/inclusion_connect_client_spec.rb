describe InclusionConnectClient, type: :model do
  let(:base_url) { "https://test.inclusion.get_token.fr" }
  let(:inclusion_connect_callback_url) { "https://example.com/callback" }
  let(:ic_state) { "test_state" }
  let(:code) { "test_code" }
  let(:access_token) { "test_access_token" }
  let(:id_token) { "test_id_token" }

  before do
    stub_const("InclusionConnectClient::CLIENT_ID", "truc")
    stub_const("InclusionConnectClient::CLIENT_SECRET", "truc secret")
    stub_const("InclusionConnectClient::BASE_URL", base_url)
  end

  describe ".auth_path" do
    let(:auth_path) { described_class.auth_path(ic_state, inclusion_connect_callback_url) }

    it "returns the correct authorization URL" do
      expect(auth_path).to eq(
        "#{base_url}/authorize/?client_id=truc&from=community&redirect_uri=" \
        "#{URI.encode_www_form_component(inclusion_connect_callback_url)}&response_type=" \
        "code&scope=openid+email&state=#{ic_state}"
      )
    end
  end

  describe ".get_token" do
    it "makes a POST request to the token endpoint with the correct data" do
      allow(Faraday).to receive(:post).with(
        URI("#{base_url}/token/"),
        {
          client_id: "truc",
          client_secret: "truc secret",
          code: code,
          grant_type: "authorization_code",
          redirect_uri: inclusion_connect_callback_url
        }
      ).and_return(instance_double("Faraday::Response", status: 200, body: "response_body"))

      response = described_class.get_token(code, inclusion_connect_callback_url)
      expect(response.status).to eq(200)
      expect(response.body).to eq("response_body")
    end
  end

  describe ".logout_path" do
    let(:logout_path) { described_class.logout_path(id_token, ic_state) }

    it "returns the correct logout URL" do
      query = {
        id_token_hint: id_token,
        state: ic_state,
        post_logout_redirect_uri: "#{ENV['HOST']}/sign_in"
      }
      expect(logout_path).to eq(
        "#{base_url}/logout?#{query.to_query}"
      )
    end
  end

  describe ".get_agent_info" do
    it "makes a GET request to the userinfo endpoint with the correct data and headers" do
      allow(Faraday).to receive(:get).with(
        "#{base_url}/userinfo/",
        { schema: "openid" },
        { "Authorization" => "Bearer #{access_token}" }
      ).and_return(instance_double("Faraday::Response", status: 200, body: "response_body"))

      response = described_class.get_agent_info(access_token)
      expect(response.status).to eq(200)
      expect(response.body).to eq("response_body")
    end
  end
end
