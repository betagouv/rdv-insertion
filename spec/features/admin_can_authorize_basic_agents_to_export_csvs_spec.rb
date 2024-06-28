describe "Admins can authorize basic agents to export csvs", :js do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department:) }
  let!(:organisation2) { create(:organisation, department:) }
  let!(:other_department) { create(:department) }
  let!(:other_organisation) { create(:organisation, department: other_department) }

  let!(:admin) { create(:agent, admin_role_in_organisations: [organisation, organisation2, other_organisation]) }
  let!(:basic_agent) { create(:agent, basic_role_in_organisations: [organisation, organisation2, other_organisation]) }
  let!(:agent_role_for_organisation) { organisation.agent_roles.find { |ar| ar.agent_id == basic_agent.id } }

  before do
    setup_agent_session(admin)
  end

  context "from configure organisation page" do
    before do
      visit organisation_category_configurations_path(organisation)
      click_link("Gérer les autorisations", href: organisation_authorized_to_export_csv_index_path(organisation))
    end

    it "displays the export authorizations of basic agents" do
      expect(page).to have_field(
        "authorized_to_export_csv_agent_role_ids_#{agent_role_for_organisation.id}", checked: false
      )
      expect(page).to have_content(basic_agent.email)
      expect(page).to have_content(basic_agent.to_s)
      expect(all('input[type="checkbox"]').size).to eq(1)
    end

    it "can toggle authorization to export csvs for basic agents" do
      find(:css, "#authorized_to_export_csv_agent_role_ids_#{agent_role_for_organisation.id}").click
      click_button("Confirmer")

      click_link("Gérer les autorisations", href: organisation_authorized_to_export_csv_index_path(organisation))
      expect(page).to have_field(
        "authorized_to_export_csv_agent_role_ids_#{agent_role_for_organisation.id}", checked: true
      )
      basic_agent.reload.agent_roles.where(organisation: department.organisations)
      agent_roles_for_organisation = basic_agent.reload.agent_roles.where(organisation: organisation)
      agent_roles_for_other_organisations = basic_agent.reload.agent_roles.where.not(organisation: organisation)
      expect(agent_roles_for_organisation).to all(have_attributes(authorized_to_export_csv: true))
      expect(agent_roles_for_other_organisations).to all(have_attributes(authorized_to_export_csv: false))

      find(:css, "#authorized_to_export_csv_agent_role_ids_#{agent_role_for_organisation.id}").click
      click_button("Confirmer")

      click_link("Gérer les autorisations", href: organisation_authorized_to_export_csv_index_path(organisation))
      expect(page).to have_field(
        "authorized_to_export_csv_agent_role_ids_#{agent_role_for_organisation.id}", checked: false
      )
      expect(basic_agent.reload.agent_roles).to all(have_attributes(authorized_to_export_csv: false))

      expect(page).to have_current_path(organisation_category_configurations_path(organisation))
    end
  end
end
