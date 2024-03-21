describe "Agents can close or reopen follow_up", :js do
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:category_orientation) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation")
  end
  let!(:configuration) { create(:configuration, organisation: organisation, motif_category: category_orientation) }
  let!(:user) do
    create(:user, organisations: [organisation])
  end
  let!(:follow_up) do
    create(:follow_up, user: user, motif_category: category_orientation)
  end

  before do
    setup_agent_session(agent)
  end

  context "from department user page" do
    it "can close and reopen a follow_up" do
      visit department_user_follow_ups_path(department_id: department.id, user_id: user.id)
      expect(page).to have_content("Clôturer")

      click_button("Clôturer")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Rouvrir")
      expect(page).to have_content("Traité le")
      expect(follow_up.reload.status).to eq("closed")
      expect(page).to have_current_path(department_user_follow_ups_path(department_id: department.id,
                                                                        user_id: user.id))

      click_button("Rouvrir")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Clôturer")
      expect(page).to have_content("Non invité")
      expect(follow_up.reload.status).to eq("not_invited")
      expect(follow_up.reload.closed_at).to eq(nil)
      expect(page).to have_current_path(department_user_follow_ups_path(department_id: department.id,
                                                                        user_id: user.id))
    end
  end

  context "from organisation user page" do
    it "can close and reopen follow_up" do
      visit organisation_user_follow_ups_path(organisation_id: organisation.id, user_id: user.id)
      expect(page).to have_content("Clôturer")

      click_button("Clôturer")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Rouvrir")
      expect(page).to have_content("Traité le")
      expect(follow_up.reload.status).to eq("closed")
      expect(page).to have_current_path(organisation_user_follow_ups_path(organisation_id: organisation.id,
                                                                          user_id: user.id))

      click_button("Rouvrir")
      expect(page).to have_content("RSA orientation")

      expect(page).to have_content("Clôturer")
      expect(page).to have_content("Non invité")
      expect(follow_up.reload.closed_at).to eq(nil)
      expect(page).to have_current_path(organisation_user_follow_ups_path(organisation_id: organisation.id,
                                                                          user_id: user.id))
    end
  end
end
