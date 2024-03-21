describe "Agents can update contact info with caf file", :js do
  let!(:agent) { create(:agent) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(:organisation, agents: [agent], department: department, rdv_solidarites_organisation_id: "1122")
  end
  let!(:rdv_solidarites_user_id) { "232324" }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_create_user(rdv_solidarites_user_id)
    stub_sync_with_rdv_solidarites_user(rdv_solidarites_user_id)
    stub_brevo
    stub_geo_api_request("127 RUE DE GRENELLE 75007 PARIS")
  end

  describe "when user is not created yet" do
    include_context "with file configuration"

    let!(:category_configuration) do
      create(:category_configuration, file_configuration: file_configuration, organisation: organisation)
    end

    it "updates the user list with the info from the csv file" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_content("hernan@crespo.com")
      expect(page).to have_content("0620022002")

      click_button("Enrichir avec des données de contacts CNAF")

      attach_file("contact-file-upload", Rails.root.join("spec/fixtures/fichier_contact_test.csv"), make_visible: true)

      expect(page).to have_content("hernan.crespo@hotmail.fr")
      expect(page).to have_content("698943255")

      click_button("Créer compte")

      expect(page).to have_button("Inviter par SMS", disabled: false)

      user = User.last

      expect(user.email).to eq("hernan.crespo@hotmail.fr")
      expect(user.phone_number).to eq("+33698943255")
    end
  end

  describe "when the user is already created" do
    include_context "with file configuration"

    let!(:category_configuration) do
      create(:category_configuration, file_configuration: file_configuration, organisation: organisation)
    end

    let!(:user) do
      create(
        :user,
        first_name: "Hernan", last_name: "Crespo", email: "hernan@crespo.com", phone_number: "0620022002",
        affiliation_number: "ISQCJQO", organisations: [organisation], rdv_solidarites_user_id:
      )
    end

    it "can update the user attributes with the info from the csv file one by one" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_content("hernan@crespo.com")
      expect(page).to have_content("+33620022002")

      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_css("a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]")

      click_button("Enrichir avec des données de contacts CNAF")

      attach_file("contact-file-upload", Rails.root.join("spec/fixtures/fichier_contact_test.csv"), make_visible: true)

      expect(page).to have_content("Nouvelles données trouvées pour Hernan Crespo")
      expect(page).to have_content("hernan.crespo@hotmail.fr")
      expect(page).to have_content("698943255")

      expect(page).to have_button("Mettre à jour").twice
      expect(page).to have_button("Tout mettre à jour")

      # it updates the email only
      click_on("Mettre à jour", match: :first)

      expect(page).to have_content("hernan.crespo@hotmail.fr")
      expect(page).to have_no_content("hernan@crespo.com")

      expect(user.reload.email).to eq("hernan.crespo@hotmail.fr")
      expect(user.reload.phone_number).to eq("+33620022002")

      click_button("Mettre à jour")

      expect(page).to have_content("+33698943255")
      expect(page).to have_no_content("+33620022002")

      expect(user.reload.phone_number).to eq("+33698943255")
    end

    it "can update all the attributes at once" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_content("hernan@crespo.com")
      expect(page).to have_content("+33620022002")

      click_button("Enrichir avec des données de contacts CNAF")

      attach_file("contact-file-upload", Rails.root.join("spec/fixtures/fichier_contact_test.csv"), make_visible: true)

      expect(page).to have_content("Nouvelles données trouvées pour Hernan Crespo")
      expect(page).to have_content("hernan.crespo@hotmail.fr")
      expect(page).to have_content("698943255")

      click_button("Tout mettre à jour")

      expect(page).to have_content("hernan.crespo@hotmail.fr")
      expect(page).to have_content("+33698943255")

      expect(user.reload.email).to eq("hernan.crespo@hotmail.fr")
      expect(user.reload.phone_number).to eq("+33698943255")
    end

    context "when user does not belong to the organisation" do
      let!(:other_organisation) do
        create(:organisation, agents: [agent], department: department, rdv_solidarites_organisation_id: "1123")
      end

      let!(:user) do
        create(
          :user,
          first_name: "Hernan", last_name: "Crespo", email: "hernan@crespo.com", phone_number: "0620022002",
          affiliation_number: "ISQCJQO", organisations: [other_organisation], rdv_solidarites_user_id:
        )
      end

      it "does not show the update button" do
        visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

        attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

        expect(page).to have_content("hernan@crespo.com")
        expect(page).to have_content("Ajouter à cette organisation")
        click_button("Enrichir avec des données de contacts CNAF")

        attach_file("contact-file-upload", Rails.root.join("spec/fixtures/fichier_contact_test.csv"),
                    make_visible: true)

        expect(page).to have_no_content("Nouvelles données trouvées pour Hernan Crespo")
      end
    end
  end
end
