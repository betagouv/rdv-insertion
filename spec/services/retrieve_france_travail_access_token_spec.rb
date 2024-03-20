describe RetrieveFranceTravailAccessToken, type: :service do
  subject do
    described_class.call
  end

  let!(:redis) { instance_double("redis") }
  let!(:access_token) { SecureRandom.uuid }

  describe "#call" do
    before do
      allow(Redis).to receive(:new).and_return(redis)
      allow(redis).to receive(:exists?)
      allow(redis).to receive(:get)
      allow(redis).to receive(:set)
      allow(redis).to receive(:close)
    end

    context "when the token is already in redis" do
      before do
        allow(redis).to receive(:exists?).with("france_travail_access_token").and_return(true)
        allow(redis).to receive(:get).with("france_travail_access_token").and_return(access_token)
      end

      it "is a success" do
        is_a_success
      end

      it "retrieves the token in redis" do
        expect(subject.access_token).to eq(access_token)
      end
    end

    context "when it is not in redis" do
      let!(:faraday) { instance_double("faraday") }

      before do
        allow(Faraday).to receive(:new).and_return(faraday)
        allow(redis).to receive(:exists?).with("france_travail_access_token").and_return(false)
        allow(faraday).to receive(:post)
          .and_return(OpenStruct.new(success?: true,
                                     body: { "access_token" => access_token,
                                             "expires_in" => 1500 }.to_json))
        allow(redis).to receive(:get).with("france_travail_access_token").and_return(access_token)
      end

      it "is a success" do
        is_a_success
      end

      it "stores the token in redis" do
        expect(redis).to receive(:set)
          .with("france_travail_access_token", access_token, ex: 1440)
        subject
      end

      it "store the token in result" do
        expect(subject.access_token).to eq(access_token)
      end

      context "when the api call fails" do
        before do
          allow(faraday).to receive(:post)
            .and_return(OpenStruct.new(success?: false, status: 400, body: "something wrong happened"))
        end

        it "is a failure" do
          is_a_failure
        end

        it "outputs the error" do
          expect(subject.errors).to contain_exactly(
            "la requête d'authentification à FT n'a pas pu aboutir.\n" \
            "Status: 400\n Body: something wrong happened"
          )
        end
      end
    end
  end
end
