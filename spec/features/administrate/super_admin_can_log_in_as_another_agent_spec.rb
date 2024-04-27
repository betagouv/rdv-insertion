describe "Super admin can log in as another agent", :js do
  let!(:super_admin_department) { create(:department) }
  let!(:super_admin_organisation1) { create(:organisation, department: super_admin_department) }
  let!(:super_admin_organisation2) { create(:organisation, department: super_admin_department) }
  let!(:super_admin) do
    create(:agent, :super_admin, organisations: [super_admin_organisation1, super_admin_organisation2])
  end
  let!(:agent_department) { create(:department) }
  let!(:agent_organisation1) { create(:organisation, department: agent_department) }
  let!(:agent_organisation2) { create(:organisation, department: agent_department) }
  let!(:agent) { create(:agent, organisations: [agent_organisation1, agent_organisation2]) }

  before do
    setup_agent_session(super_admin)
  end

  context "when agent is super_admin" do
    it "can log in as another agent" do
      visit super_admins_root_path
      expect(page).to have_content(agent.last_name)
      expect(page).to have_content(super_admin.last_name)
      click_link(agent.last_name)

      expect(page).to have_link("Se logger en tant que",
                                href: super_admins_agent_impersonation_path(agent_id: agent.id))
      click_link("Se logger en tant que")

      # Verify that the super admin is now logged in as the agent
      expect(page).to have_current_path(organisations_path)
      expect(page).to have_content("Vous êtes connecté.e en tant que #{agent.first_name} #{agent.last_name}")
      # We check the organisations displayed to check that it is really the agent's account
      expect(page).to have_content(agent_department.name)
      expect(page).to have_content(agent_organisation1.name)
      expect(page).to have_content(agent_organisation2.name)
      expect(page).to have_no_content(super_admin_department.name)
      expect(page).to have_no_content(super_admin_organisation1.name)
      expect(page).to have_no_content(super_admin_organisation2.name)

      # Verify that the super admin can switch back to its account by clicking on the Super admin button
      expect(page).to have_link("Revenir à ma session",
                                href: super_admins_agent_impersonation_path(agent_id: agent.id))
      click_link("Revenir à ma session")
      expect(page).to have_current_path(organisations_path)

      # Verify it's really the super admin account by checking the organisations displayed
      expect(page).to have_content(super_admin_department.name)
      expect(page).to have_content(super_admin_organisation1.name)
      expect(page).to have_content(super_admin_organisation2.name)
      expect(page).to have_no_content(agent_department.name)
      expect(page).to have_no_content(agent_organisation1.name)
      expect(page).to have_no_content(agent_organisation2.name)
    end
  end
end
