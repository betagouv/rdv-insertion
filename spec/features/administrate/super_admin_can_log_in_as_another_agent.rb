describe "Super admin can log in as another agent" do
  let!(:super_admin_department) { create(:department) }
  let!(:super_admin_organisation_1) { create(:organisation, department: super_admin_department) }
  let!(:super_admin_organisation_2) { create(:organisation, department: super_admin_department) }
  let!(:super_admin) { create(:agent, :super_admin, organisations: [super_admin_organisation_1, super_admin_organisation_2]) }

  let!(:agent_department) { create(:department) }
  let!(:agent_organisation_1) { create(:organisation, department: agent_department) }
  let!(:agent_organisation_2) { create(:organisation, department: agent_department) }
  let!(:agent) { create(:agent, organisations: [agent_organisation_1, agent_organisation_2]) }

  before do
    setup_agent_session(super_admin)
  end

  context "when agent is super_admin" do
    it "can log in as another agent" do
      visit super_admins_root_path
      expect(page).to have_content("#{agent.last_name}")
      expect(page).to have_content("#{super_admin.last_name}")
      click_link("#{agent.last_name}")

      expect(page).to have_link("Se logger en tant que", href: sign_in_as_super_admins_agent_path(agent))
      click_link("Se logger en tant que")

      # Verify that the super admin is now logged in as the agent
      expect(page).to have_current_path(organisations_path)
      expect(page).to have_content("Vous êtes connecté.e en tant que #{agent.first_name} #{agent.last_name}")
      # We check the organisations displayed to check that it is really the agent's account
      expect(page).to have_content(agent_department.name)
      expect(page).to have_content(agent_organisation_1.name)
      expect(page).to have_content(agent_organisation_2.name)
      expect(page).to have_no_content(super_admin_department.name)
      expect(page).to have_no_content(super_admin_organisation_1.name)
      expect(page).to have_no_content(super_admin_organisation_2.name)

      # Verify that the super admin can switch back to its account by clicking on the Super admin button
      click_link("Super admin")
      expect(page).to have_current_path(super_admins_root_path)
      expect(page).to have_content("#{super_admin.first_name} #{super_admin.last_name}, vous avez été reconnecté.e à votre compte")

      # Verify it's really the super admin account by checking the organisations displayed
      click_link("Retour à l'app")
      expect(page).to have_current_path(organisations_path)
      expect(page).to have_content(super_admin_department.name)
      expect(page).to have_content(super_admin_organisation_1.name)
      expect(page).to have_content(super_admin_organisation_2.name)
      expect(page).to have_no_content(agent_department.name)
      expect(page).to have_no_content(agent_organisation_1.name)
      expect(page).to have_no_content(agent_organisation_2.name)
    end
  end
end
