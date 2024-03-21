describe "Agents can close or reopen rdv_context", :js do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
  end
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: category_orientation)
  end
  let!(:user) do
    create(:user, organisations: [organisation])
  end
  let!(:rdv_context) do
    create(:rdv_context, user: user, motif_category: category_orientation)
  end

  before do
    setup_agent_session(agent)
  end

  context "from department user page" do
    it "can close and reopen a rdv_context" do
      visit department_user_rdv_contexts_path(department_id: department.id, user_id: user.id)
      expect(page).to have_content("Clôturer")

      click_button("Clôturer")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Rouvrir")
      expect(page).to have_content("Traité le")
      expect(rdv_context.reload.status).to eq("closed")
      expect(page).to have_current_path(department_user_rdv_contexts_path(department_id: department.id,
                                                                          user_id: user.id))

      click_button("Rouvrir")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Clôturer")
      expect(page).to have_content("Non invité")
      expect(rdv_context.reload.status).to eq("not_invited")
      expect(rdv_context.reload.closed_at).to eq(nil)
      expect(page).to have_current_path(department_user_rdv_contexts_path(department_id: department.id,
                                                                          user_id: user.id))
    end
  end

  context "from organisation user page" do
    it "can close and reopen rdv_context" do
      visit organisation_user_rdv_contexts_path(organisation_id: organisation.id, user_id: user.id)
      expect(page).to have_content("Clôturer")

      click_button("Clôturer")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Rouvrir")
      expect(page).to have_content("Traité le")
      expect(rdv_context.reload.status).to eq("closed")
      expect(page).to have_current_path(organisation_user_rdv_contexts_path(organisation_id: organisation.id,
                                                                            user_id: user.id))

      click_button("Rouvrir")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Clôturer")
      expect(page).to have_content("Non invité")
      expect(rdv_context.reload.closed_at).to eq(nil)
      expect(page).to have_current_path(organisation_user_rdv_contexts_path(organisation_id: organisation.id,
                                                                            user_id: user.id))
    end
  end
end
