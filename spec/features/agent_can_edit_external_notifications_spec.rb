describe "Agents can edit organisation", :js do
  let!(:agent) { create(:agent) }
  let!(:organisation) { create(:organisation) }
  let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let!(:agent_role) { create(:agent_role, organisation: organisation, agent: agent, access_level: "admin") }

  before do
    setup_agent_session(agent)
    stub_request(:patch,
                 "#{ENV['RDV_SOLIDARITES_URL']}/api/v1/organisations/#{organisation.rdv_solidarites_organisation_id}")
      .to_return(status: 200, body: { organisation: { id: organisation.rdv_solidarites_organisation_id } }.to_json)
  end

  context "organisation edit" do
    it "allows to activate external notifications" do
      visit organisation_category_configurations_path(organisation)
      within "#category_configuration_#{category_configuration.id}" do
        click_link("Modifier")
      end

      fill_in "category_configuration[email_to_notify_rdv_changes]", with: "test@test.com"
      fill_in "category_configuration[email_to_notify_no_available_slots]", with: "test1@test.com"

      click_button "Enregistrer"

      expect(page).to have_content("Notifier sur toutes les prises")
      expect(page).to have_content("test@test.com")
      expect(page).to have_content("test1@test.com")
    end
  end
end
