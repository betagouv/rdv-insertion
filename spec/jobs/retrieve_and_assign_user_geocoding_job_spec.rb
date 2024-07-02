describe RetrieveAndAssignUserGeocodingJob do
  subject do
    described_class.new.perform(user.id)
  end

  let!(:user) { create(:user, address:, organisations: [organisation], geocoding: nil) }
  let!(:address) { "78940 garancières la queue 28 rue la Garance" }
  let!(:organisation) { create(:organisation, department:) }
  let!(:department) { create(:department, number: "78") }
  let!(:geocoding_params) do
    {
      street_ban_id: "78513_0053",
      post_code: "78940",
      city_code: "78513",
      longitude: 1.759386,
      latitude: 48.804796,
      city: "La Queue-les-Yvelines",
      street: "Rue de la Garance",
      house_number: "28"
    }
  end

  before do
    allow(RetrieveGeocoding).to receive(:call)
      .with(address:, department_number: "78")
      .and_return(OpenStruct.new(success?: true, geocoding_params:))
  end

  it "creates a geocoding record and assigns it to the user" do
    expect { subject }.to change(Geocoding, :count).by(1)
    geocoding = user.reload.geocoding
    expect(geocoding.attributes.symbolize_keys).to match(hash_including(geocoding_params))
  end

  context "when the user has a geocoding attached already" do
    let!(:geocoding) { create(:geocoding, user:) }

    it "updates the assigned geocoding with the retrieved geocoding params" do
      expect { subject }.not_to change(Geocoding, :count)
      expect(geocoding.reload.attributes.symbolize_keys).to match(hash_including(geocoding_params))
      expect(geocoding.user_id).to eq(user.id)
    end

    context "when no geocoding params could be retrieved" do
      before do
        allow(RetrieveGeocoding).to receive(:call)
          .with(address:, department_number: "78")
          .and_return(OpenStruct.new(success?: true, geocoding_params: nil))
      end

      it "destroys the associated geocoding" do
        expect { subject }.to change(Geocoding, :count).by(-1)
        expect(user.reload.geocoding).to be_nil
      end
    end
  end
end
