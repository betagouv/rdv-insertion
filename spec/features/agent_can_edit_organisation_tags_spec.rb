describe "Agents can edit organisation tags", :js do
  let!(:agent) { create(:agent) }
  let!(:organisation) { create(:organisation) }
  let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let!(:agent_role) { create(:agent_role, organisation: organisation, agent: agent, access_level: 1) }

  let(:tag_value) { "prout" }

  before do
    setup_agent_session(agent)
  end

  context "from organisation page" do
    it "allows to edit the organisation tags" do
      visit organisation_category_configurations_path(organisation)
      page.fill_in "tag_value", with: tag_value
      click_button("Créer le tag")

      tag = find(".badge")
      expect(tag).to have_content(tag_value)
      expect(organisation.reload.tags.first.value).to eq(tag_value)
    end
  end
end
