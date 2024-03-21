describe "Agents can add or remove user from organisations", :js do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department
      # needed for the organisation users page
    )
  end
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: motif_category)
  end
  let!(:motif_category) { create(:motif_category, name: "Entretien SIAE") }
  let!(:rdv_solidarites_user_id) { 243 }
  let!(:user) do
    create(
      :user,
      organisations: [organisation],
      rdv_solidarites_user_id: rdv_solidarites_user_id
    )
  end
  let!(:other_org) { create(:organisation, department: department) }
  let!(:other_config) { create(:category_configuration, organisation: other_org, motif_category: other_motif_category) }
  let!(:other_motif_category) { create(:motif_category, name: "RSA suivi") }

  before do
    setup_agent_session(agent)
  end

  context "from department user page" do
    it "can add to an organisation" do
      stub_create_user_profiles = stub_request(
        :post, "#{ENV['RDV_SOLIDARITES_URL']}/api/rdvinsertion/user_profiles/create_many"
      ).to_return(
        status: 200,
        body: {
          user: { id: rdv_solidarites_user_id,
                  organisation_ids: [
                    organisation.rdv_solidarites_organisation_id, other_org.rdv_solidarites_organisation_id
                  ] }
        }.to_json
      )
      stub_update_user = stub_request(
        :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users/#{rdv_solidarites_user_id}"
      ).to_return(
        status: 200,
        body: {
          user: { id: rdv_solidarites_user_id }
        }.to_json
      )

      visit department_user_path(department, user)

      expect(page).to have_content(organisation.name)
      expect(page).to have_no_content(other_org.name)

      click_link("Ajouter ou retirer une organisation")

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(other_org.name)
      expect(page).to have_select(
        "users_organisation[motif_category_id]", options: ["Aucune catégorie", "RSA suivi"]
      )
      select "Aucune catégorie", from: "users_organisation[motif_category_id]"

      click_button("+ Ajouter")

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(other_org.name)
      expect(page).to have_content(user.last_name)

      expect(stub_create_user_profiles).to have_been_requested
      expect(stub_update_user).to have_been_requested
      expect(user.reload.organisation_ids).to contain_exactly(organisation.id, other_org.id)
      expect(user.reload.motif_categories).not_to include(other_motif_category)
    end

    context "when a motif category is specified" do
      it "adds the user in that specific category" do
        stub_create_user_profiles = stub_request(
          :post, "#{ENV['RDV_SOLIDARITES_URL']}/api/rdvinsertion/user_profiles/create_many"
        ).to_return(
          status: 200,
          body: {
            user: { id: rdv_solidarites_user_id,
                    organisation_ids: [
                      organisation.rdv_solidarites_organisation_id, other_org.rdv_solidarites_organisation_id
                    ] }
          }.to_json
        )

        stub_update_user = stub_request(
          :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users/#{rdv_solidarites_user_id}"
        ).to_return(
          status: 200,
          body: {
            user: { id: rdv_solidarites_user_id }
          }.to_json
        )

        visit department_user_path(department, user)

        expect(page).to have_content(organisation.name)
        expect(page).to have_no_content(other_org.name)

        click_link("Ajouter ou retirer une organisation")

        expect(page).to have_content(organisation.name)
        expect(page).to have_content(other_org.name)
        expect(page).to have_select(
          "users_organisation[motif_category_id]", options: ["Aucune catégorie", "RSA suivi"]
        )

        select "RSA suivi", from: "users_organisation[motif_category_id]"

        click_button("+ Ajouter")

        expect(page).to have_content(organisation.name)
        expect(page).to have_content(other_org.name)
        expect(page).to have_content(user.last_name)

        expect(stub_create_user_profiles).to have_been_requested
        expect(stub_update_user).to have_been_requested
        expect(user.reload.organisation_ids).to contain_exactly(organisation.id, other_org.id)
        expect(user.reload.motif_categories).to include(other_motif_category)
      end
    end

    context "when the user has no rdv_solidarites_user_id" do
      let!(:user) { create(:user, organisations: [organisation], rdv_solidarites_user_id: nil) }

      it "recreates the user on rdvs and directly adds it to the right organisations" do
        stub_create_user = stub_request(
          :post, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/users"
        ).to_return(
          status: 200,
          body: {
            user: { id: rdv_solidarites_user_id }
          }.to_json
        )

        visit department_user_path(department, user)

        expect(page).to have_content(organisation.name)
        expect(page).to have_no_content(other_org.name)

        click_link("Ajouter ou retirer une organisation")

        expect(page).to have_content(organisation.name)
        expect(page).to have_content(other_org.name)
        expect(page).to have_select(
          "users_organisation[motif_category_id]", options: ["Aucune catégorie", "RSA suivi"]
        )
        select "Aucune catégorie", from: "users_organisation[motif_category_id]"

        click_button("+ Ajouter")

        expect(page).to have_content(organisation.name)
        expect(page).to have_content(other_org.name)
        expect(page).to have_content(user.last_name)

        expect(stub_create_user).to have_been_requested
        expect(user.reload.organisation_ids).to contain_exactly(organisation.id, other_org.id)
        expect(user.reload.motif_categories).not_to include(other_motif_category)
      end
    end

    it "can remove from org" do
      stub_delete_user_profile = stub_request(
        :delete, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/user_profiles"
      ).with(
        headers: { "Content-Type" => "application/json" }.merge(shared_secret_credentials_hash(agent)),
        query: {
          "user_id" => rdv_solidarites_user_id, "organisation_id" => organisation.rdv_solidarites_organisation_id
        }
      ).to_return(status: 204)

      visit department_user_path(department, user)
      expect(page).to have_content(organisation.name)
      expect(page).to have_no_content(other_org.name)

      click_link("Ajouter ou retirer une organisation")

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(other_org.name)
      expect(page).to have_button("- Retirer", disabled: false)

      accept_confirm(
        "Cette action va supprimer définitivement la fiche de l'usager, êtes-vous sûr de vouloir la supprimer ?"
      ) do
        click_button("- Retirer")
      end

      expect(page).to have_content("Filtrer")
      expect(page).to have_content("Créer usager(s)")

      expect(stub_delete_user_profile).to have_been_requested
      expect(user.reload.organisation_ids).to eq([])
      expect(user.deleted?).to eq(true)
    end
  end

  context "from organisation page" do
    let!(:user) do
      create(
        :user,
        organisations: [organisation, other_org],
        rdv_solidarites_user_id: rdv_solidarites_user_id
      )
    end

    it "returns to the department list if the user is removed from the org" do
      stub_delete_user_profile = stub_request(
        :delete, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/user_profiles"
      ).with(
        headers: { "Content-Type" => "application/json" }.merge(shared_secret_credentials_hash(agent)),
        query: {
          "user_id" => rdv_solidarites_user_id, "organisation_id" => organisation.rdv_solidarites_organisation_id
        }
      ).to_return(status: 204)

      visit organisation_user_path(organisation, user)
      expect(page).to have_content(organisation.name)
      expect(page).to have_content(other_org.name)

      click_link("Ajouter ou retirer une organisation")

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(other_org.name)

      expect(page).to have_button("- Retirer", disabled: false)
      expect(page).to have_button("- Retirer", disabled: true)

      click_button("- Retirer")

      expect(page).to have_content("Filtrer")
      expect(page).to have_content("Créer usager(s)")

      expect(stub_delete_user_profile).to have_been_requested
      expect(user.reload.organisation_ids).to eq([other_org.id])
      expect(user.deleted?).to eq(false)
    end
  end
end
