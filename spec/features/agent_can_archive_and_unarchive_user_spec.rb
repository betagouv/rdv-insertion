describe "Agents can archive and unarchive user", :js do
  let!(:agent) { create(:agent) }
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, agents: [agent], department: department) }
  let!(:user) do
    create(:user, organisations: [organisation])
  end

  before { setup_agent_session(agent) }

  describe "from show page" do
    it "can archive and unarchive the user" do
      visit organisation_user_path(organisation, user)
      expect(page).to have_button("Archiver le dossier")

      click_button("Archiver le dossier")

      expect(page).to have_content("Le dossier sera archivé sur toutes les organisations")
      fill_in "Motif d'archivage:", with: "déménagement"

      click_button "Oui"

      expect(page).to have_content "Dossier archivé"
      expect(page).to have_content "Motif d'archivage"
      expect(page).to have_content "déménagement"

      expect(Archive.count).to eq(1)

      expect(page).to have_button "Rouvrir le dossier"
      click_button "Rouvrir le dossier"
      expect(page).to have_content "Le dossier sera rouvert"
      click_button "Oui"

      expect(page).to have_no_content "Dossier archivé"
      expect(page).to have_no_content "Motif d'archivage"
      expect(page).to have_no_content "déménagement"

      expect(page).to have_content("Archiver le dossier")

      expect(Archive.count).to eq(0)
    end

    context "when the user is archived in another department" do
      let!(:other_department) { create(:department) }
      let!(:other_org) { create(:organisation, department: other_department, users: [user]) }
      let!(:archive) { create(:archive, user: user, department: create(:department)) }

      it "can still archive in agent department" do
        visit department_user_path(department, user)
        expect(page).to have_button("Archiver le dossier")

        click_button("Archiver le dossier")

        expect(page).to have_content("Le dossier sera archivé sur toutes les organisations")
        fill_in "Motif d'archivage:", with: "déménagement"

        click_button "Oui"

        expect(page).to have_content "Dossier archivé"
        expect(page).to have_content "Motif d'archivage"
        expect(page).to have_content "déménagement"

        expect(Archive.count).to eq(2)

        expect(page).to have_button "Rouvrir le dossier"
        click_button "Rouvrir le dossier"
        expect(page).to have_content "Le dossier sera rouvert"
        click_button "Oui"

        expect(page).to have_no_content "Dossier archivé"
        expect(page).to have_no_content "Motif d'archivage"
        expect(page).to have_no_content "déménagement"

        expect(page).to have_content("Archiver le dossier")

        expect(Archive.count).to eq(1)
      end
    end

    context "when the agent does not belong to all users orgs inside the deparment" do
      let!(:other_org) { create(:organisation, department: department, users: [user]) }

      it "is not allowed to archive the user" do
        visit organisation_user_path(organisation, user)

        expect(page).to have_button("Archiver le dossier", disabled: true)
      end
    end
  end

  describe "from upload page" do
    include_context "with file configuration"

    let!(:category_configuration) do
      create(:category_configuration, file_configuration: file_configuration, organisation: organisation)
    end
    let!(:user) do
      create(
        :user,
        email: "hernan@crespo.com",
        first_name: "hernan",
        organisations: [organisation]
      )
    end
    let!(:archive) do
      create(:archive, user: user, department: department, archiving_reason: "CDI")
    end

    it "can unarchive an user" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_button "Rouvrir le dossier"
      expect(page).to have_content "Dossier archivé"
      expect(page).to have_content "CDI"

      expect(page).to have_no_button "Inviter par SMS"

      click_button "Rouvrir le dossier"

      expect(page).to have_content "Dossier de l'usager rouvert avec succès"
      click_button "OK"

      expect(page).to have_button "Inviter par SMS"
    end

    context "when the archive is in another department" do
      let!(:archive) do
        create(:archive, user: user, department: create(:department))
      end

      it "does not show the user as archived" do
        visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

        attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

        expect(page).to have_button "Inviter par SMS"

        expect(page).to have_no_button "Rouvrir le dossier"
        expect(page).to have_no_content "Dossier archivé"
      end
    end
  end
end
