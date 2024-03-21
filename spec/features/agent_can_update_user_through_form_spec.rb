describe "Agents can update user through form", :js do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department,
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
      # needed for the organisation users page
      configurations: [configuration],
      slug: "org1"
    )
  end

  let!(:configuration) do
    create(:configuration)
  end

  let!(:user) do
    create(
      :user,
      first_name: "Milla", last_name: "Jovovich", rdv_solidarites_user_id: rdv_solidarites_user_id,
      organisations: [organisation]
    )
  end

  let!(:affiliation_number) { "122334455" }
  let!(:role) { "demandeur" }
  let!(:department_internal_id) { "030303" }
  let!(:email) { "milla@jovovich.com" }
  let!(:phone_number) { "0782605941" }

  let!(:rdv_solidarites_user_id) { 2323 }
  let!(:rdv_solidarites_organisation_id) { 3234 }

  describe "#update" do
    before do
      setup_agent_session(agent)
      stub_sync_with_rdv_solidarites_user(rdv_solidarites_user_id)
      # Somehow the tests fail on CI if we do not put this line, the before_save :set_status callback is not
      # triggered on the follow-ups when we create them (in Users::Save) and so there is an error when redirected
      # to show page after update
      allow_any_instance_of(FollowUp).to receive(:status).and_return("not_invited")
    end

    it "can update the user" do
      visit edit_organisation_user_path(organisation, user)

      page.fill_in "user_first_name", with: "Milo"
      click_button "Enregistrer"

      expect(page).to have_content("Milo")
      expect(user.reload.first_name).to eq("Milo")
    end

    context "when there is conflict with another department_internal_id" do
      context "when it is in the same department" do
        let!(:other_user) do
          create(:user, id: 22, department_internal_id: department_internal_id, organisations: [organisation])
        end

        it "cannot update the user" do
          visit edit_organisation_user_path(organisation, user)
          page.fill_in "user_department_internal_id", with: department_internal_id

          click_button "Enregistrer"

          expect(page).to have_content(
            "Un usager avec le même ID interne au département se trouve au sein du département: [22]"
          )
          expect(user.reload.department_internal_id).not_to eq(department_internal_id)
        end
      end

      context "when it is outside the department" do
        let!(:other_user) do
          create(
            :user,
            id: 22, department_internal_id: department_internal_id,
            organisations: [create(:organisation, department: create(:department))]
          )
        end

        it "can update the user" do
          visit edit_organisation_user_path(organisation, user)
          page.fill_in "user_department_internal_id", with: department_internal_id

          click_button "Enregistrer"

          expect(page).to have_content(department_internal_id)

          expect(user.reload.department_internal_id).to eq(department_internal_id)
        end
      end
    end

    context "when there is conflict with another uid" do
      context "when it is in the same department" do
        let!(:other_user) do
          create(:user, id: 22, affiliation_number: affiliation_number, role: role, organisations: [organisation])
        end

        it "cannot update the user" do
          visit edit_organisation_user_path(organisation, user)
          page.fill_in "user_affiliation_number", with: affiliation_number
          page.select role, from: "user_role"

          click_button "Enregistrer"

          expect(page).to have_content(
            "Un usager avec le même numéro CAF et rôle se trouve au sein du département: [22]"
          )
          expect(user.reload.affiliation_number).not_to eq(affiliation_number)
        end
      end

      context "when it is outside the department" do
        let!(:other_user) do
          create(
            :user,
            id: 22, affiliation_number: affiliation_number,
            organisations: [create(:organisation, department: create(:department))]
          )
        end

        it "can update the user" do
          visit edit_organisation_user_path(organisation, user)
          page.fill_in "user_affiliation_number", with: affiliation_number
          page.select role, from: "user_role"

          click_button "Enregistrer"

          expect(page).to have_content(affiliation_number)

          expect(user.reload.affiliation_number).to eq(affiliation_number)
        end
      end
    end

    context "when there is a conflict with the mail and the first name" do
      let!(:other_user) do
        create(:user, id: 22, email: email, first_name: "milla")
      end

      it "cannot update the user" do
        visit edit_organisation_user_path(organisation, user)

        page.fill_in "user_email", with: email

        click_button "Enregistrer"

        expect(page).to have_content(
          "Un usager avec le même email et même prénom est déjà enregistré: [22]"
        )
        expect(user.reload.email).not_to eq(email)
      end
    end

    context "when there is a conflict with the phone_number and the first name" do
      let!(:other_user) do
        create(:user, id: 22, phone_number: phone_number, first_name: "milla")
      end

      it "cannot update the user" do
        visit edit_organisation_user_path(organisation, user)

        page.fill_in "user_phone_number", with: phone_number

        click_button "Enregistrer"

        expect(page).to have_content(
          "Un usager avec le même numéro de téléphone et même prénom est déjà enregistré: [22]"
        )
        expect(user.reload.phone_number).not_to eq(phone_number)
      end
    end
  end
end
