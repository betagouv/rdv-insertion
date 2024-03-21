describe "Super admin can manage organisations" do
  let!(:super_admin) { create(:agent, :super_admin) }
  let!(:department1) { create(:department) }
  let!(:organisation1) { create(:organisation, department: department1) }
  let!(:agent1) { create(:agent, organisations: [organisation1], super_admin: false) }
  let!(:lieu1) { create(:lieu, organisation: organisation1) }
  let!(:motif_category) { create(:motif_category) }
  let!(:category_configuration1) do
    create(:category_configuration, organisation: organisation1, motif_category: motif_category)
  end
  let!(:department2) { create(:department) }
  let!(:organisation2) { create(:organisation, department: department2) }
  let!(:agent2) { create(:agent, organisations: [organisation2], super_admin: false) }
  let!(:lieu2) { create(:lieu, organisation: organisation2) }

  before do
    setup_agent_session(super_admin)
  end

  context "from organisations admin index page" do
    before { visit super_admins_organisations_path }

    it "can see the list of organisations" do
      expect(page).to have_current_path(super_admins_organisations_path)
      expect(page).to have_content(organisation1.id)
      expect(page).to have_content(organisation1.name)
      expect(page).to have_content(department1.name)
      expect(page).to have_content(organisation2.id)
      expect(page).to have_content(organisation2.name)
      expect(page).to have_content(department2.name)
    end

    it "can navigate to an organisation show page" do
      expect(page).to have_link(href: super_admins_organisation_path(organisation1))
      expect(page).to have_link(href: super_admins_organisation_path(organisation2))

      first(:link, href: super_admins_organisation_path(organisation1)).click

      expect(page).to have_current_path(super_admins_organisation_path(organisation1))
    end

    it "can navigate to an organisation new page" do
      expect(page).to have_link("Création organisation", href: new_super_admins_organisation_path)

      click_link(href: new_super_admins_organisation_path)

      expect(page).to have_current_path(new_super_admins_organisation_path)
    end

    it "can navigate to an organisation edit page" do
      expect(page).to have_link("Modifier", href: edit_super_admins_organisation_path(organisation1))
      expect(page).to have_link("Modifier", href: edit_super_admins_organisation_path(organisation2))

      click_link(href: edit_super_admins_organisation_path(organisation1))

      expect(page).to have_current_path(edit_super_admins_organisation_path(organisation1))
    end

    it "cannot delete an organisation" do
      expect(page).to have_no_link("Supprimer")
    end
  end

  context "from organisation admin show page" do
    before { visit super_admins_organisation_path(organisation1) }

    it "can see an organisation's details" do
      expect(page).to have_current_path(super_admins_organisation_path(organisation1))
      expect(page).to have_content("Détails #{organisation1.name} (#{department1.name})")
      expect(page).to have_css("dt", id: "id", text: "ID")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.id)
      expect(page).to have_css("dt", id: "name", text: "NOM")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.name)
      expect(page).to have_css("dt", id: "phone_number", text: "NUMÉRO DE TÉLÉPHONE")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.phone_number)
      expect(page).to have_css(
        "dt", id: "rdv_solidarites_organisation_id", text: "ID DE L'ORGANISATION DANS RDV-SOLIDARITÉS"
      )
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.rdv_solidarites_organisation_id)
      expect(page).to have_css("dt", id: "slug", text: "DÉSIGNATION DANS LE FICHIER USAGERS")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.slug)
      expect(page).to have_css("dt", id: "department", text: "DÉPARTEMENT")
      expect(page).to have_css("dd", class: "attribute-data", text: department1.name)
      expect(page).to have_css("dt", id: "email", text: "EMAIL")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.email)
      expect(page).to have_css("dt", id: "safir_code", text: "CODE SAFIR")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.safir_code)
      expect(page).to have_css("dt", id: "independent_from_cd", text: "INDÉPENDANTE DU CD")
      expect(page).to have_css("dd", class: "attribute-data", text: organisation1.independent_from_cd)
      expect(page).to have_css("dt", id: "agent_roles", text: "AGENT ROLES")
      expect(page).to have_css("td", class: "cell-data--belongs-to", text: agent1.to_s)
      expect(page).to have_no_css("td", class: "cell-data--belongs-to", text: agent2.to_s)
      expect(page).to have_css("dt", id: "lieux", text: "LIEUX")
      expect(page).to have_css("td", class: "cell-data--string", text: lieu1.name)
      expect(page).to have_no_css("td", class: "cell-data--belongs-to", text: lieu2.name)
      expect(page).to have_css("dt", id: "motif_categories", text: "MOTIF CATEGORIES")
      expect(page).to have_css(
        "a[href=\"#{super_admins_motif_category_path(motif_category)}\"]",
        class: "action-show", text: motif_category.name
      )
    end

    it "can navigate to an organisation edit page" do
      expect(page).to have_link(
        "Modifier #{organisation1.name} (#{department1.name})", href: edit_super_admins_organisation_path(organisation1)
      )

      click_link("Modifier #{organisation1.name} (#{department1.name})")

      expect(page).to have_current_path(edit_super_admins_organisation_path(organisation1))
    end

    it "cannot delete a organisation" do
      expect(page).to have_no_link("Supprimer")
    end
  end

  context "from organisation admin new page" do
    let!(:new_organisation_rdv_solidarites_id) { 5 }

    before { visit new_super_admins_organisation_path }

    it "can create an organisation" do
      stub_retrieve_rdv_solidarites_organisation = stub_request(
        :get, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}"
      ).to_return(
        status: 200,
        body: {
          organisation: {
            id: new_organisation_rdv_solidarites_id,
            email: "some@email.fr",
            name: "Some name",
            phone_number: "0102030405",
            verticale: "rdv_solidarites"
          }
        }.to_json
      )
      stub_retrieve_webhook_endpoint = stub_request(
        :get, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}/" \
              "webhook_endpoints?target_url=#{ENV['HOST']}/rdv_solidarites_webhooks"
      ).to_return(
        status: 200,
        body: {
          webhook_endpoints: []
        }.to_json
      )
      stub_create_webhook_endpoint = stub_request(
        :post, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}/" \
               "webhook_endpoints"
      ).to_return(
        status: 200,
        body: {
          webhook_endpoint: {
            id: 1,
            target_url: "#{ENV['HOST']}/rdv_solidarites_webhooks"
          }
        }.to_json
      )
      stub_update_rdv_solidarites_organisation = stub_request(
        :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}"
      ).to_return(
        status: 200,
        body: {
          organisation: {
            id: new_organisation_rdv_solidarites_id,
            email: "some@email.fr",
            name: "Some name",
            phone_number: "0102030405",
            verticale: "rdv_insertion"
          }
        }.to_json
      )

      expect(page).to have_current_path(new_super_admins_organisation_path)
      expect(page).to have_content("Création Organisation")
      expect(page).to have_css(
        "label[for=\"organisation_rdv_solidarites_organisation_id\"]",
        text: "ID de l'organisation dans RDV-Solidarités"
      )
      expect(page).to have_field("organisation[rdv_solidarites_organisation_id]")
      expect(page).to have_css("label[for=\"organisation_department_id-selectized\"]", text: "Department")
      expect(page).to have_field("organisation_department_id-selectized")
      expect(page).to have_button("Enregistrer")

      fill_in "organisation_rdv_solidarites_organisation_id", with: "5"
      first("div.selectize-input").click(wait: 20)
      first("div.option", text: department1.name).click

      click_button("Enregistrer")

      expect(stub_retrieve_rdv_solidarites_organisation).to have_been_requested
      expect(stub_retrieve_webhook_endpoint).to have_been_requested.at_least_once
      expect(stub_create_webhook_endpoint).to have_been_requested
      expect(stub_update_rdv_solidarites_organisation).to have_been_requested
      expect(page).to have_current_path(super_admins_organisation_path(Organisation.last))
      expect(page).to have_content("Organisation a été correctement créé(e)")
      expect(page).to have_content("Détails Some name")
    end

    context "when a required attribute is missing" do
      it "returns an error" do
        stub_retrieve_rdv_solidarites_organisation = stub_request(
          :get, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}"
        ).to_return(
          status: 200,
          body: {
            organisation: {
              id: new_organisation_rdv_solidarites_id,
              email: "some@email.fr",
              name: "Some name",
              phone_number: "0102030405",
              verticale: "rdv_solidarites"
            }
          }.to_json
        )
        stub_retrieve_webhook_endpoint = stub_request(
          :get, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}/" \
                "webhook_endpoints?target_url=#{ENV['HOST']}/rdv_solidarites_webhooks"
        )
        stub_create_webhook_endpoint = stub_request(
          :post, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}/" \
                 "webhook_endpoints"
        )
        stub_update_rdv_solidarites_organisation = stub_request(
          :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{new_organisation_rdv_solidarites_id}"
        )

        fill_in "organisation_rdv_solidarites_organisation_id", with: "5"

        click_button("Enregistrer")

        expect(stub_retrieve_rdv_solidarites_organisation).to have_been_requested
        expect(stub_retrieve_webhook_endpoint).not_to have_been_requested.at_least_once
        expect(stub_create_webhook_endpoint).not_to have_been_requested
        expect(stub_update_rdv_solidarites_organisation).not_to have_been_requested
        expect(page).to have_content("1 erreur ont empêché Organisation d'être sauvegardé(e)")
        expect(page).to have_content("Département doit exister")
        expect(page).to have_no_content("Détails Some name")
      end
    end
  end

  context "from organisation admin edit page" do
    before { visit edit_super_admins_organisation_path(organisation1) }

    it "can edit an organisation" do
      stub_update_rdv_solidarites_organisation = stub_request(
        :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{organisation1.rdv_solidarites_organisation_id}"
      ).to_return(
        status: 200,
        body: {
          organisation: {
            id: organisation1.rdv_solidarites_organisation_id,
            email: "some@email.fr",
            name: "Some other name",
            phone_number: "0102030405",
            verticale: "rdv_insertion"
          }
        }.to_json
      )

      expect(page).to have_current_path(edit_super_admins_organisation_path(organisation1))
      expect(page).to have_content("Modifier #{organisation1.name} (#{department1.name})")
      expect(page).to have_css("label[for=\"organisation_name\"]", text: "Nom")
      expect(page).to have_field("organisation[name]", with: organisation1.name)
      expect(page).to have_css("label[for=\"organisation_phone_number\"]", text: "Numéro de téléphone")
      expect(page).to have_field("organisation[phone_number]", with: organisation1.phone_number)
      expect(page).to have_css(
        "label[for=\"organisation_rdv_solidarites_organisation_id\"]", text: "ID de l'organisation dans RDV-Solidarités"
      )
      expect(page).to have_field(
        "organisation[rdv_solidarites_organisation_id]", with: organisation1.rdv_solidarites_organisation_id
      )
      expect(page).to have_css("label[for=\"organisation_slug\"]", text: "Désignation dans le fichier usagers")
      expect(page).to have_field("organisation[slug]", with: organisation1.slug)
      expect(page).to have_css("label[for=\"organisation_department_id-selectized\"]", text: "Department")
      within("div.selectize-input") do
        expect(page).to have_field("organisation_department_id-selectized")
        expect(page).to have_css("div.item", text: department1.name)
      end
      expect(page).to have_css("label[for=\"organisation_email\"]", text: "Email")
      expect(page).to have_field("organisation[email]", with: organisation1.email)
      expect(page).to have_css("label[for=\"organisation_safir_code\"]", text: "Code SAFIR")
      expect(page).to have_field("organisation[safir_code]", with: organisation1.safir_code)
      expect(page).to have_css("label[for=\"organisation_independent_from_cd\"]", text: "Indépendante du CD")
      expect(page).to have_field("organisation[independent_from_cd]")
      expect(page).to have_button("Enregistrer")

      fill_in "organisation_name", with: "Some other name"

      click_button("Enregistrer")

      expect(stub_update_rdv_solidarites_organisation).to have_been_requested
      expect(page).to have_current_path(super_admins_organisation_path(organisation1))
      expect(page).to have_content("Organisation a été correctement modifié(e)")
      expect(page).to have_content("Détails Some other name")
    end

    context "when a required attribute is missing" do
      it "returns an error" do
        stub_update_rdv_solidarites_organisation = stub_request(
          :patch, "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{organisation1.rdv_solidarites_organisation_id}"
        )

        expect(page).to have_current_path(edit_super_admins_organisation_path(organisation1))

        fill_in "organisation_name", with: ""

        click_button("Enregistrer")

        expect(stub_update_rdv_solidarites_organisation).not_to have_been_requested
        expect(page).to have_content("1 erreur ont empêché Organisation d'être sauvegardé(e)")
        expect(page).to have_content("Nom doit être rempli(e)")
        expect(page).to have_no_content("Détails #{organisation1.name} (#{department1.name})")
      end
    end
  end

  context "when the agent is not a super admin" do
    let!(:agent) { create(:agent, super_admin: false) }

    before do
      setup_agent_session(agent)
    end

    it "cannot access the index page" do
      visit super_admins_organisations_path

      expect(page).to have_current_path(organisations_path)
    end

    it "cannot access the new page" do
      visit new_super_admins_organisation_path(organisation1)

      expect(page).to have_current_path(organisations_path)
    end

    it "cannot access the show page" do
      visit super_admins_organisation_path(organisation1)

      expect(page).to have_current_path(organisations_path)
    end

    it "cannot access the edit page" do
      visit edit_super_admins_organisation_path(organisation1)

      expect(page).to have_current_path(organisations_path)
    end
  end
end
