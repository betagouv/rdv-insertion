describe "Agents can edit users tags", :js do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:organisation) do
    create(
      :organisation,
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id
    )
  end
  let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
  let!(:user) do
    create(
      :user,
      first_name: "Milla", last_name: "Jovovich", rdv_solidarites_user_id: rdv_solidarites_user_id,
      organisations: [organisation]
    )
  end

  let!(:rdv_solidarites_user_id) { 2323 }
  let!(:rdv_solidarites_organisation_id) { 3234 }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_update_user(rdv_solidarites_user_id)
    organisation.tags << Tag.create!(value: "prout")
  end

  context "the user page" do
    it "allows to edit tags" do
      visit organisation_user_path(organisation, user)
      click_button("Ajouter ou retirer un tag")
      modal = find(".modal")
      tag_list = find_by_id("tags_list")

      modal.click_button("+ Assigner")
      expect(tag_list).to have_content("prout")
      expect(user.reload.tags.first.value).to eq("prout")

      modal.click_button("- Retirer")
      expect(tag_list).to have_content("-")
      expect(user.reload.tags).to be_empty

      find(".btn-close").click
    end
  end
end
