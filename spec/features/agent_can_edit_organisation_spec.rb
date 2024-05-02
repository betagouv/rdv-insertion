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
      click_link("Modifier", href: edit_organisation_path(organisation))

      page.fill_in "organisation_safir_code", with: "153425"
      click_button "Enregistrer"

      expect(page).to have_content("153425")
      expect(organisation.reload.safir_code).to eq("153425")
    end
  end
end
