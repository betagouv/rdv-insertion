describe "Agent can invite users by batch from index" do
  let!(:department) { create(:department) }

  let!(:organisation) { create(:organisation, department: department) }
  let!(:motif_category) { create(:motif_category) }
  let!(:configuration) { create(:configuration, organisation: organisation, motif_category: motif_category) }
  let!(:motif) { create(:motif, motif_category: motif_category, organisation: organisation) }

  let!(:agent) { create(:agent, organisations: [organisation]) }

  let!(:user1) { create(:user, last_name: "Dhobb", organisations: [organisation]) }
  let!(:follow_up1) { create(:follow_up, user: user1, motif_category: motif_category) }
  let!(:user2) { create(:user, last_name: "Blanc", organisations: [organisation]) }
  let!(:follow_up2) { create(:follow_up, user: user2, motif_category: motif_category) }
  let!(:user3) { create(:user, last_name: "Villeneuve", organisations: [organisation]) }
  let!(:follow_up3) { create(:follow_up, user: user3, motif_category: motif_category) }
  let!(:invitation3) do
    create(:invitation, follow_up: follow_up3, user: user3, department: department,
                        organisations: [organisation], created_at: Time.zone.now, format: "sms")
  end
  let!(:user4) { create(:user, last_name: "Neuville", organisations: [organisation]) }

  let!(:rdv_solidarites_token1) { "123456" }
  let!(:rdv_solidarites_token2) { "234567" }
  let!(:rdv_solidarites_token3) { "345678" }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_invitation_requests(user1.rdv_solidarites_user_id, rdv_solidarites_token1)
    stub_rdv_solidarites_invitation_requests(user2.rdv_solidarites_user_id, rdv_solidarites_token2)
    stub_rdv_solidarites_invitation_requests(user3.rdv_solidarites_user_id, rdv_solidarites_token3)
    stub_geo_api_request(user1.address)
    stub_geo_api_request(user2.address)
    stub_geo_api_request(user3.address)
    stub_request(
      :get,
      /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
    ).to_return(status: 200, body: { "creneau_availability" => true }.to_json, headers: {})
    stub_brevo
    follow_up1.set_status
    follow_up1.save!
    follow_up2.set_status
    follow_up2.save!
    follow_up3.set_status
    follow_up3.save!
  end

  context "when agent is at organisation level" do
    it "can export non invited users to a batch_actions page" do
      visit organisation_users_path(organisation, motif_category_id: motif_category.id)

      expect(page).to have_link(
        "Envoyer des invitations aux non-invités",
        href: "#{new_organisation_batch_action_path(organisation)}?motif_category_id=#{motif_category.id}"
      )
      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)

      click_link "Envoyer des invitations aux non-invités"

      expect(page).to have_current_path(
        "#{new_organisation_batch_action_path(organisation)}?motif_category_id=#{motif_category.id}"
      )
      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_no_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)
    end

    it "can invite a selection of users" do
      visit "#{new_organisation_batch_action_path(organisation)}?motif_category_id=#{motif_category.id}"

      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_no_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)

      expect(page).to have_button("Actions pour toute la sélection", disabled: false)
      expect(page).to have_content("Inviter par SMS").exactly(2).times
      expect(page).to have_content("Inviter par Email").exactly(2).times
      expect(page).to have_no_css("i.fas.fa-check")
      expect(page).to have_no_css("i.fas.fa-redo-alt")

      click_button("Actions pour toute la sélection", wait: 10)
      click_button("Invitation par sms", wait: 10)

      expect(page).to have_no_content("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check").exactly(2).times
      expect(page).to have_css("i.fas.fa-redo-alt").exactly(2).times
    end

    it "can return to index page with the same arguments" do
      visit organisation_users_path(organisation, motif_category_id: motif_category.id)
      select("Non invité", from: "user_status")
      click_link "Envoyer des invitations aux non-invités"

      expect(page).to have_button("Retour au suivi")
      click_button("Retour au suivi")

      expect(page).to have_current_path(
        organisation_users_path(organisation, motif_category_id: motif_category.id, status: "not_invited")
      )
    end
  end

  context "when agent is at department level" do
    it "can export non invited users to a batch_actions page" do
      visit department_users_path(department, motif_category_id: motif_category.id)

      expect(page).to have_link(
        "Envoyer des invitations aux non-invités",
        href: "#{new_department_batch_action_path(department)}?motif_category_id=#{motif_category.id}"
      )
      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)

      click_link "Envoyer des invitations aux non-invités"

      expect(page).to have_current_path(
        "#{new_department_batch_action_path(department)}?motif_category_id=#{motif_category.id}"
      )
      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_no_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)
    end

    it "can invite a selection of users" do
      visit "#{new_department_batch_action_path(department)}?motif_category_id=#{motif_category.id}"

      expect(page).to have_content(user1.last_name)
      expect(page).to have_content(user2.last_name)
      expect(page).to have_no_content(user3.last_name)
      expect(page).to have_no_content(user4.last_name)

      expect(page).to have_button("Actions pour toute la sélection", disabled: false)
      expect(page).to have_content("Inviter par SMS").exactly(2).times
      expect(page).to have_content("Inviter par Email").exactly(2).times
      expect(page).to have_no_css("i.fas.fa-check")
      expect(page).to have_no_css("i.fas.fa-redo-alt")

      click_button("Actions pour toute la sélection", wait: 10)
      click_button("Invitation par sms", wait: 10)

      expect(page).to have_no_content("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check").exactly(2).times
      expect(page).to have_css("i.fas.fa-redo-alt").exactly(2).times
    end

    it "can return to index page with the same arguments" do
      visit department_users_path(department, motif_category_id: motif_category.id)
      select("Non invité", from: "user_status")
      click_link "Envoyer des invitations aux non-invités"

      expect(page).to have_button("Retour au suivi")
      click_button("Retour au suivi")

      expect(page).to have_current_path(
        department_users_path(department, motif_category_id: motif_category.id, status: "not_invited")
      )
    end
  end
end
