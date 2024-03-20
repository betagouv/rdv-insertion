describe OutgoingWebhooks::SendFranceTravailWebhook, type: :service do
  subject do
    described_class.call(payload:, timestamp:)
  end

  let!(:payload) do
    {
      "idOrigine" => 330,
      "libelleStructure" => "CD de DIE",
      "codeSafir" => "123245",
      "objet" => "RSA - Orientation : rdv sur site"
    }
  end
  let!(:access_token) { SecureRandom.uuid }

  let!(:timestamp) { Time.zone.parse("05/03/2024") }

  let!(:request_headers) do
    {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    }
  end

  before do
    allow(RetrieveFranceTravailAccessToken).to receive(:call)
      .and_return(OpenStruct.new(success?: true, access_token:))
    allow(Faraday).to receive(:post).and_return(OpenStruct.new(success?: true))
  end

  it "is a success" do
    is_a_success
  end

  it "calls the france travail api" do
    expect(Faraday).to receive(:post)
      .with("https://francetravailfakerdvurl.fr", payload.to_json, request_headers)
    subject
  end

  it "creates a receipt" do
    expect { subject }.to change(WebhookReceipt, :count).by(1)
    webhook_receipt = WebhookReceipt.last
    expect(webhook_receipt).to have_attributes(resource_model: "Rdv", timestamp:, resource_id: 330)
  end

  context "when it is an old update" do
    let!(:webhook_receipt) do
      create(
        :webhook_receipt,
        webhook_endpoint_id: nil, resource_model: "Rdv", resource_id: 330,
        timestamp: timestamp + 2.minutes
      )
    end

    it "is a success" do
      is_a_success
    end

    it "does not call the ft api" do
      expect(Faraday).not_to receive(:post)
      subject
    end

    it "does not create a receipt" do
      expect { subject }.not_to change(WebhookReceipt, :count)
    end
  end

  context "when the api call fails" do
    before do
      allow(Faraday).to receive(:post).and_return(OpenStruct.new(success?: false, status: 400,
                                                                 body: "something wrong happened"))
    end

    it "is a failure" do
      is_a_failure
    end

    it "stores the error" do
      expect(subject.errors).to contain_exactly("Impossible d'appeler l'endpoint de rdv FT.\n" \
                                                "Status: 400\n Body: something wrong happened")
    end
  end

  context "when the service retrieving the token fails" do
    before do
      allow(RetrieveFranceTravailAccessToken).to receive(:call)
        .and_return(OpenStruct.new(success?: false, errors: ["could not retrieve token"]))
    end

    it "is a failure" do
      is_a_failure
    end

    it "outputs the error" do
      expect(subject.errors).to contain_exactly("could not retrieve token")
    end
  end
end
