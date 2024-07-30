describe "Agents can archive and unarchive user", :js do
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department:) }
  let!(:user) { create(:user, organisations: [organisation]) }

  before { setup_agent_session(agent) }

  describe "from show page" do
    it "can archive and unarchive the user" do
      visit organisation_user_path(organisation, user)
      expect(page).to have_link("Archiver le dossier")

      click_link("Archiver le dossier")

      expect(page).to have_content("Le dossier sera archivé dans l'organisation")
      fill_in "archive_archiving_reason", with: "déménagement"

      click_button "Archiver"

      expect(page).to have_content "Dossier archivé"

      expect(Archive.count).to eq(1)
      expect(Archive.first.user).to eq(user)
      expect(Archive.first.archiving_reason).to eq("déménagement")

      expect(page).to have_link "Rouvrir le dossier"
      click_link "Rouvrir le dossier"
      expect(page).to have_content "Êtes vous sûr ?"
      expect(page).to have_content "Le dossier de #{user} sera rouvert dans l'organisation #{organisation.name}"
      click_button "Rouvrir le dossier"

      expect(page).to have_no_content "Dossier archivé"

      expect(page).to have_content("Archiver le dossier")

      expect(Archive.count).to eq(0)
    end

    context "when the user is archived in another organisation" do
      let!(:other_org) { create(:organisation, department: department, users: [user]) }
      let!(:archive) { create(:archive, user: user, organisation: other_org) }

      it "can still archive in other org" do
        visit organisation_user_path(organisation, user)
        expect(page).to have_link("Archiver le dossier")

        click_link("Archiver le dossier")

        expect(page).to have_content("Le dossier sera archivé dans l'organisation")
        fill_in "archive_archiving_reason", with: "déménagement"

        click_button "Archiver"

        expect(page).to have_content "Dossier archivé"

        expect(Archive.count).to eq(2)

        expect(page).to have_link "Rouvrir le dossier"
        click_link "Rouvrir le dossier"
        expect(page).to have_content "Êtes vous sûr ?"
        expect(page).to have_content "Le dossier de #{user} sera rouvert dans l'organisation #{organisation.name}"
        click_button "Rouvrir le dossier"

        expect(page).to have_no_content "Dossier archivé"
        expect(page).to have_no_content "Motif d'archivage"
        expect(page).to have_no_content "déménagement"

        expect(page).to have_content("Archiver le dossier")

        expect(Archive.count).to eq(1)
      end
    end
  end

  describe "from upload page" do
    include_context "with file configuration"

    let!(:category_configuration) { create(:category_configuration, file_configuration:, organisation:) }
    let!(:user) { create(:user, email: "hernan@crespo.com", first_name: "hernan", organisations: [organisation]) }
    let!(:archive) { create(:archive, user:, organisation:, archiving_reason: "CDI") }

    it "can unarchive an user" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_button "Rouvrir le dossier"
      expect(page).to have_content "Dossier archivé"

      expect(page).to have_no_button "Inviter par SMS"

      click_button "Rouvrir le dossier"

      expect(page).to have_content "Dossier de l'usager rouvert avec succès"
      click_button "OK"

      expect(page).to have_button "Inviter par SMS"
    end

    context "when the archive is in another organisation" do
      let!(:other_org) { create(:organisation, department: department, users: [user]) }
      let!(:archive) do
        create(:archive, user:, organisation: other_org)
      end

      it "does not show the user as archived" do
        visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

        attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

        expect(page).to have_button "Inviter par SMS"

        expect(page).to have_no_button "Rouvrir le dossier"
        expect(page).to have_no_content "Dossier archivé"
      end
    end

    context "when department level" do
      let!(:other_org) { create(:organisation, department:, users: [user]) }
      let!(:agent) { create(:agent, organisations: [organisation, other_org]) }
      let!(:archive) { create(:archive, user:, organisation:, archiving_reason: "CDI") }

      before do
        visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

        attach_file(
          "users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true
        )
      end

      context "when the user is archived in all organisations of department" do
        let!(:archive2) { create(:archive, user:, organisation: other_org, archiving_reason: "CDI") }

        it "displays the user as archived but with no reopen button" do
          expect(page).to have_no_button "Rouvrir le dossier"
          expect(page).to have_css(".fa-link")
          expect(page).to have_content "Dossier archivé"
        end
      end

      context "when the user is partially archived in the department" do
        it "does not display the user as archived" do
          expect(page).to have_no_button "Rouvrir le dossier"
          expect(page).to have_button "Inviter par SMS"
          expect(page).to have_no_content "Dossier archivé"
        end
      end
    end
  end
end
