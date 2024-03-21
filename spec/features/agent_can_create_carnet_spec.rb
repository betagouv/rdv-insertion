describe "Agents can create a carnet", :js do
  let!(:agent) { create(:agent, email: "someone@gouv.fr") }
  let!(:department) { create(:department, carnet_de_bord_deploiement_id: "9213124", number: "75") }
  let!(:organisation) { create(:organisation, agents: [agent], department: department) }
  let!(:carnet_de_bord_carnet_id) { "12312ZD9A" }
  let!(:cdb_payload) do
    {
      rdviUserEmail: "someone@gouv.fr",
      deploymentId: "9213124",
      notebook: {
        nir: "180333147687266",
        externalId: "8383",
        firstname: "Hernan",
        lastname: "Crespo",
        dateOfBirth: "1987-11-21",
        mobileNumber: "+33620022002",
        email: "hernan@crespo.com",
        cafNumber: "ISQCJQO",
        address1: "127 avenue de Ségur",
        postalCode: "75007",
        city: "Paris"
      }
    }
  end

  before do
    setup_agent_session(agent)
    stub_request(:get, RetrieveGeolocalisation::API_ADRESSE_URL).with(
      headers: { "Content-Type" => "application/json" },
      query: { "q" => "127 RUE DE GRENELLE 75007 PARIS" }
    ).to_return(
      body: {
        "features" => [
          {
            "properties" => {
              "name" => "127 avenue de Ségur",
              "postcode" => "75007",
              "city" => "Paris",
              "context" => "75",
              "id" => "75107_8909",
              "citycode" => "12312"
            },
            "geometry" => { "coordinates" => [123, 232] }

          }
        ]
      }.to_json
    )
  end

  describe "from upload page" do
    include_context "with file configuration"

    let!(:category_configuration) do
      create(:category_configuration, file_configuration: file_configuration, organisation: organisation)
    end

    before { stub_rdv_solidarites_create_user("some-id") }

    it "can create a carnet from the upload page" do
      carnet_de_bord_stub = stub_request(
        :post, "https://demo.carnetdebord.inclusion.beta.gouv.fr/api/notebooks"
      ).with(
        body: cdb_payload.to_json,
        headers: {
          "Authorization" => "Bearer secret_token",
          "Content-Type" => "application/json"
        }
      ).to_return(body: { "notebookId" => carnet_de_bord_carnet_id }.to_json)

      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_button("Créer carnet", disabled: true)
      click_button("Créer compte")
      expect(page).to have_button("Créer carnet", disabled: false)

      click_button("Créer carnet")
      expect(page).to have_no_content("Créer carnet")
      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_css(
        "a[href=\"https://demo.carnetdebord.inclusion.beta.gouv.fr/manager/carnets/12312ZD9A\"]"
      )

      user = User.last
      expect(user.carnet_de_bord_carnet_id).to eq(carnet_de_bord_carnet_id)

      expect(carnet_de_bord_stub).to have_been_requested
    end
  end

  describe "from show page" do
    let!(:user) do
      create(
        :user,
        organisations: [organisation], nir: "180333147687266", department_internal_id: "8383",
        first_name: "Hernan", last_name: "Crespo", birth_date: Time.zone.parse("1987-11-21"),
        phone_number: "+33620022002", email: "hernan@crespo.com", affiliation_number: "ISQCJQO",
        address: "127 RUE DE GRENELLE 75007 PARIS"
      )
    end

    it "can create a carnet from the show page" do
      carnet_de_bord_stub = stub_request(
        :post, "https://demo.carnetdebord.inclusion.beta.gouv.fr/api/notebooks"
      ).with(
        body: cdb_payload.to_json,
        headers: {
          "Authorization" => "Bearer secret_token",
          "Content-Type" => "application/json"
        }
      ).to_return(body: { "notebookId" => carnet_de_bord_carnet_id }.to_json)

      visit organisation_user_path(organisation, user)

      expect(page).to have_button("Créer carnet")
      expect(page).to have_no_content("Voir sur Carnet de bord")
      click_button("Créer carnet")

      expect(page).to have_content("Voir sur Carnet de bord")
      expect(page).to have_no_button("Créer carnet")

      expect(page).to have_css(
        "a[href=\"https://demo.carnetdebord.inclusion.beta.gouv.fr/manager/carnets/12312ZD9A\"]"
      )
      expect(carnet_de_bord_stub).to have_been_requested
    end
  end
end
