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
    it "allows to set a code safir" do
      visit organisation_category_configurations_path(organisation)
      within "#category_configuration_#{category_configuration.id}" do
        click_link("Modifier")
      end

      check "category_configuration[notify_rdv_changes]"
      fill_in "category_configuration[notify_rdv_changes_email]", with: "test@test.com"
      check "category_configuration[notify_out_of_slots]"
      fill_in "category_configuration[notify_out_of_slots_email]", with: "test1@test.com"

      click_button "Enregistrer"

      expect(page).to have_content("L'email suivant est notifié")
      expect(page).to have_content("test@test.com")
      expect(page).to have_content("test1@test.com")
    end
  end
end
