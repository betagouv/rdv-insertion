describe "Super admin can manage users" do
  let!(:super_admin) { create(:agent, :super_admin) }
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:rdv_solidarites_user_id) { user.rdv_solidarites_user_id }

  before do
    setup_agent_session(super_admin)
  end

  context "from users admin index page" do
    before { visit super_admins_users_path }

    it "can see the list of users" do
      expect(page).to have_current_path(super_admins_users_path)
      expect(page).to have_content(user.id)
      expect(page).to have_content(user.first_name)
      expect(page).to have_content(user.last_name)
      expect(page).to have_content(user.email)
    end

    it "can navigate to a user show page" do
      expect(page).to have_link(href: super_admins_user_path(user))

      first(:link, href: super_admins_user_path(user)).click

      expect(page).to have_current_path(super_admins_user_path(user))
    end

    it "can navigate to a user edit page" do
      expect(page).to have_link("Modifier", href: edit_super_admins_user_path(user))

      click_link(href: edit_super_admins_user_path(user))

      expect(page).to have_current_path(edit_super_admins_user_path(user))
    end

    it "cannot create a user" do
      expect(page).to have_no_link("Création usager")
    end

    it "cannot delete a user" do
      expect(page).to have_no_link("Supprimer")
    end
  end

  context "from user admin show page" do
    before { visit super_admins_user_path(user) }

    it "can see a user's details" do
      expect(page).to have_current_path(super_admins_user_path(user))
      expect(page).to have_content("Détails #{user.first_name} #{user.last_name}")
      expect(page).to have_css("dt", id: "id", text: "ID")
      expect(page).to have_css("dd", class: "attribute-data", text: user.id)
      expect(page).to have_css("dt", id: "rdv_solidarites_user_id", text: "ID DE L'USAGER RDV-SOLIDARITÉS")
      expect(page).to have_css("dd", class: "attribute-data", text: user.rdv_solidarites_user_id)
      expect(page).to have_css("dt", id: "title", text: "CIVILITÉ")
      expect(page).to have_css("dd", class: "attribute-data", text: user.title)
      expect(page).to have_css("dt", id: "first_name", text: "PRÉNOM")
      expect(page).to have_css("dd", class: "attribute-data", text: user.first_name)
      expect(page).to have_css("dt", id: "last_name", text: "NOM")
      expect(page).to have_css("dd", class: "attribute-data", text: user.last_name)
      expect(page).to have_css("dt", id: "birth_name", text: "NOM DE NAISSANCE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.birth_name)
      expect(page).to have_css("dt", id: "email", text: "EMAIL")
      expect(page).to have_css("dd", class: "attribute-data", text: user.email)
      expect(page).to have_css("dt", id: "address", text: "ADRESSE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.address)
      expect(page).to have_css("dt", id: "phone_number", text: "TÉLÉPHONE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.phone_number)
      expect(page).to have_css("dt", id: "birth_date", text: "DATE DE NAISSANCE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.birth_date)
      expect(page).to have_css("dt", id: "role", text: "RÔLE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.role)
      expect(page).to have_css("dt", id: "affiliation_number", text: "NUMÉRO CAF")
      expect(page).to have_css("dd", class: "attribute-data", text: user.affiliation_number)
      expect(page).to have_css("dt", id: "nir", text: "NUMÉRO DE SÉCURITÉ SOCIALE")
      expect(page).to have_css("dd", class: "attribute-data", text: user.nir)
      expect(page).to have_css("dt", id: "department_internal_id", text: "ID INTERNE AU DÉPARTEMENT")
      expect(page).to have_css("dd", class: "attribute-data", text: user.department_internal_id)
      expect(page).to have_css("dt", id: "france_travail_id", text: "ID FRANCE TRAVAIL")
      expect(page).to have_css("dd", class: "attribute-data", text: user.france_travail_id)
      expect(page).to have_css("dt", id: "rights_opening_date", text: "DATE D'ENTRÉE FLUX")
      expect(page).to have_css("dd", class: "attribute-data", text: user.rights_opening_date)
      expect(page).to have_css("dt", id: "organisations", text: "ORGANISATION(S)")
      expect(page).to have_css(
        "a[href=\"#{super_admins_organisation_path(organisation)}\"]", class: "action-show", text: organisation.name
      )
      expect(page).to have_css("dt", id: "tags", text: "TAGS")
    end

    it "can navigate to a user edit page" do
      expect(page).to have_link(
        "Modifier #{user.first_name} #{user.last_name}", href: edit_super_admins_user_path(user)
      )

      click_link("Modifier #{user.first_name} #{user.last_name}")

      expect(page).to have_current_path(edit_super_admins_user_path(user))
    end

    it "cannot delete a user" do
      expect(page).to have_no_link("Supprimer")
    end
  end

  context "from user admin edit page" do
    before do
      stub_sync_with_rdv_solidarites_user(rdv_solidarites_user_id)
      # Somehow the tests fail on CI if we do not put this line, the before_save :set_status callback is not
      # triggered on the follow-ups when we create them (in Users::Save) and so there is an error when redirected
      # to show page after update
      allow_any_instance_of(FollowUp).to receive(:status).and_return("not_invited")
      visit edit_super_admins_user_path(user)
    end

    it "can edit a user" do
      expect(page).to have_current_path(edit_super_admins_user_path(user))
      expect(page).to have_content("Modifier #{user.first_name} #{user.last_name}")
      expect(page).to have_css("label[for=\"user_rdv_solidarites_user_id\"]", text: "ID de l'usager RDV-Solidarités")
      expect(page).to have_field("user[rdv_solidarites_user_id]", with: user.rdv_solidarites_user_id)
      expect(page).to have_css("label[for=\"user_title-selectized\"]", text: "Civilité")
      within first("div.selectize-input") do
        expect(page).to have_field("user_title-selectized")
        expect(page).to have_css("div.item", text: user.title)
      end
      expect(page).to have_css("label[for=\"user_first_name\"]", text: "Prénom")
      expect(page).to have_field("user[first_name]", with: user.first_name)
      expect(page).to have_css("label[for=\"user_last_name\"]", text: "Nom")
      expect(page).to have_field("user[last_name]", with: user.last_name)
      expect(page).to have_css("label[for=\"user_birth_name\"]", text: "Nom de naissance")
      expect(page).to have_field("user[birth_name]", with: user.birth_name)
      expect(page).to have_css("label[for=\"user_email\"]", text: "Email")
      expect(page).to have_field("user[email]", with: user.email)
      expect(page).to have_css("label[for=\"user_address\"]", text: "Adresse")
      expect(page).to have_field("user[address]", with: user.address)
      expect(page).to have_css("label[for=\"user_phone_number\"]", text: "Téléphone")
      expect(page).to have_field("user[phone_number]", with: user.phone_number)
      expect(page).to have_css("label[for=\"user_birth_date\"]", text: "Date de naissance")
      expect(page).to have_field("user[birth_date]", with: user.birth_date)
      within all("div.selectize-input")[1] do # this is fetching the second selectize-input
        expect(page).to have_field("user_role-selectized")
        expect(page).to have_css("div.item", text: user.role)
      end
      expect(page).to have_css("label[for=\"user_affiliation_number\"]", text: "Numéro CAF")
      expect(page).to have_field("user[affiliation_number]", with: user.affiliation_number)
      expect(page).to have_css("label[for=\"user_nir\"]", text: "Numéro de sécurité sociale")
      expect(page).to have_field("user[nir]", with: user.nir)
      expect(page).to have_css("label[for=\"user_department_internal_id\"]", text: "ID interne au département")
      expect(page).to have_field("user[department_internal_id]", with: user.department_internal_id)
      expect(page).to have_css("label[for=\"user_france_travail_id\"]", text: "ID France Travail")
      expect(page).to have_field("user[france_travail_id]", with: user.france_travail_id)
      expect(page).to have_css("label[for=\"user_rights_opening_date\"]", text: "Date d'entrée flux")
      expect(page).to have_field("user[rights_opening_date]", with: user.rights_opening_date)
      expect(page).to have_button("Enregistrer")

      fill_in "user_last_name", with: "Newname"

      click_button("Enregistrer")

      expect(page).to have_current_path(super_admins_user_path(user))
      expect(page).to have_content("Usager a été correctement modifié(e)")
      expect(page).to have_content("Détails #{user.first_name} Newname")
    end

    context "when a required attribute is missing" do
      it "returns an error" do
        fill_in "user_first_name", with: ""
        fill_in "user_last_name", with: "Newname"

        click_button("Enregistrer")

        expect(page).to have_content("1 erreur ont empêché Usager d'être sauvegardé(e)")
        expect(page).to have_content("Prénom doit être rempli(e)")
        expect(page).to have_no_content("Détails #{user.first_name} Newname")
      end
    end
  end

  context "when the agent is not a super admin" do
    let!(:agent) { create(:agent, super_admin: false) }

    before do
      setup_agent_session(agent)
    end

    it "cannot access the index page" do
      visit super_admins_users_path

      expect(page).to have_current_path(organisations_path)
    end

    it "cannot access the show page" do
      visit super_admins_user_path(user)

      expect(page).to have_current_path(organisations_path)
    end

    it "cannot access the edit page" do
      visit edit_super_admins_user_path(user)

      expect(page).to have_current_path(organisations_path)
    end
  end
end
