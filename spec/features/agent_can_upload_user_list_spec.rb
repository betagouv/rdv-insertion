describe "Agents can upload user list", :js do
  include_context "with file configuration"

  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department:,
      rdv_solidarites_organisation_id:,
      # needed for the organisation users page
      category_configurations: [category_configuration],
      slug: "org1"
    )
  end
  let!(:motif) { create(:motif, organisation: organisation, motif_category: motif_category) }

  let!(:category_configuration) { create(:category_configuration, motif_category:, file_configuration:) }

  let!(:other_org_from_same_department) { create(:organisation, department:) }
  let!(:other_department) { create(:department) }
  let!(:other_org_from_other_department) { create(:organisation, department: other_department) }

  let!(:now) { Time.zone.parse("05/10/2022") }

  let!(:motif_category) { create(:motif_category) }
  let!(:rdv_solidarites_user_id) { 2323 }
  let!(:rdv_solidarites_organisation_id) { 3234 }

  before do
    setup_agent_session(agent)
    stub_user_creation(rdv_solidarites_user_id)
    stub_request(
      :get,
      /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
    ).to_return(status: 200, body: { "creneau_availability" => true }.to_json, headers: {})
  end

  context "at organisation level" do
    before { travel_to now }

    it "can create and invite user" do
      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      ### Upload

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_content("Civilité")
      expect(page).to have_content("M")
      expect(page).to have_content("Prénom")
      expect(page).to have_content("Hernan")
      expect(page).to have_content("Nom")
      expect(page).to have_content("Crespo")
      expect(page).to have_content("Numéro CAF")
      expect(page).to have_content("ISQCJQO")
      expect(page).to have_content("Rôle")
      expect(page).to have_content("DEM")
      expect(page).to have_content("ID Editeur")
      expect(page).to have_content("8383")
      expect(page).to have_content("Email")
      expect(page).to have_content("hernan@crespo.com")
      expect(page).to have_content("Téléphone")
      expect(page).to have_content("0620022002")
      expect(page).to have_content("NIR")
      expect(page).to have_content("1803331476872")
      expect(page).to have_content("Création compte")
      expect(page).to have_button("Créer compte", disabled: false)
      expect(page).to have_content("Invitation SMS")
      expect(page).to have_button("Inviter par SMS", disabled: true)
      expect(page).to have_content("Invitation mail")
      expect(page).to have_button("Inviter par Email", disabled: true)
      expect(page).to have_content("Invitation courrier")
      expect(page).to have_button("Générer courrier", disabled: true)

      ### Create

      click_button("Créer compte")

      expect(page).to have_button("Inviter par SMS", disabled: false)
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
      expect(page).to have_no_button("Créer compte")

      user = User.last
      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_css("a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]")

      expect(user.first_name).to eq("Hernan")
      expect(user.last_name).to eq("Crespo")
      expect(user.affiliation_number).to eq("ISQCJQO")
      expect(user.title).to eq("monsieur")
      expect(user.role).to eq("demandeur")
      expect(user.nir).to eq("180333147687266")
      expect(user.email).to eq("hernan@crespo.com")
      expect(user.phone_number).to eq("+33620022002")
      expect(user.department_internal_id).to eq("8383")
      expect(user.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
      expect(user.created_through).to eq("rdv_insertion_upload_page")
      expect(user.created_from_structure).to eq(organisation)
      # It added the user to the category
      expect(user.motif_categories).to include(motif_category)

      ### Invite by sms

      click_button("Inviter par SMS")

      expect(page).to have_no_button("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).to have_css("i.fas.fa-redo-alt")
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)

      invitation = Invitation.last

      expect(invitation.format).to eq("sms")
      expect(invitation.user).to eq(user)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-invite by sms

      click_button(class: "reinvitation-sms")

      expect(page).to have_content("Une invitation sms a déjà été envoyée aujourd'hui à cet usager")
      click_button("OK")

      invitation = Invitation.last
      invitation.destroy!

      click_button(class: "reinvitation-sms")

      expect(page).to have_no_content("Une invitation sms a déjà été envoyée aujourd'hui à cet usager")
      expect(invitation.format).to eq("sms")
      expect(invitation.user).to eq(user)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-upload the file

      visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_no_button("Créer compte")
      expect(page).to have_no_button("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).to have_css("i.fas.fa-redo-alt")

      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
    end

    describe "Category selection" do
      context "when no option is selected" do
        it "redirects to category selection" do
          visit new_organisation_upload_path(organisation)

          expect(page).to have_content("Aucune catégorie de suivi")
          expect(page).to have_content(motif_category.name)

          click_link(motif_category.name)

          expect(page).to have_content("Choisissez un fichier d'usagers")
          expect(page).to have_content(motif_category.name)
        end

        context "when no category is selected" do
          it "can create users without affecting a category" do
            visit new_organisation_upload_path(organisation)

            expect(page).to have_content("Aucune catégorie de suivi")
            expect(page).to have_content(motif_category.name)

            click_link("Aucune catégorie de suivi")

            expect(page).to have_content("Choisissez un fichier d'usagers")

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_button("Créer compte")
            expect(page).to have_no_content("Invitation SMS")
            expect(page).to have_no_content("Invitation mail")
            expect(page).to have_no_content("Invitation courrier")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            user = User.last
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )

            expect(user.first_name).to eq("Hernan")
            expect(user.last_name).to eq("Crespo")
            expect(user.affiliation_number).to eq("ISQCJQO")
            expect(user.title).to eq("monsieur")
            expect(user.role).to eq("demandeur")
            expect(user.nir).to eq("180333147687266")
            expect(user.email).to eq("hernan@crespo.com")
            expect(user.phone_number).to eq("+33620022002")
            expect(user.department_internal_id).to eq("8383")
            expect(user.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            # It did not add categories
            expect(user.motif_categories).to eq([])
          end
        end
      end
    end

    describe "cannot assign all the attributes depending on the organisation type" do
      before { organisation.update! organisation_type: "siae" }

      it "cannot asssign nir and department_internal_id for SIAE" do
        visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

        expect(page).to have_content("Choisissez un fichier d'usagers")
        attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                    make_visible: true)

        click_button("Créer compte")

        expect(page).to have_css("i.fas.fa-link")

        user = User.last

        expect(user.first_name).to eq("Hernan")
        expect(user.last_name).to eq("Crespo")
        expect(user.affiliation_number).to eq("ISQCJQO")
        expect(user.title).to eq("monsieur")
        expect(user.role).to eq("demandeur")
        expect(user.email).to eq("hernan@crespo.com")
        expect(user.phone_number).to eq("+33620022002")
        expect(user.address).to eq("127 RUE DE GRENELLE 75007 PARIS")

        expect(user.nir).to be_nil
        expect(user.department_internal_id).to be_nil
      end
    end

    describe "Users matching" do
      describe "nir matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              nir: "180333147687266", address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
              phone_number: "+33782605941", email: "hernan@crespa.com",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")

            ## it displays the db attributes
            expect(page).to have_content("Crespa")
            expect(page).to have_content("+33782605941")
            expect(page).to have_content("hernan@crespa.com")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end
      end

      describe "uid (affiliation_number/role) matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org common with the agent" do
          let!(:agent) { create(:agent, organisations: [organisation, other_org_from_same_department]) }

          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO",
              address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
              phone_number: "+33782605941", email: "hernan@crespa.com",
              organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Ajouter à cette organisation")

            ## it does not display the db attributes
            expect(page).to have_no_content("Crespa")
            expect(page).to have_no_content("+33782605941")
            expect(page).to have_no_content("hernan@crespa.com")
            expect(page).to have_content("Cresp")
            expect(page).to have_content("0620022002")
            expect(page).to have_content("hernan@crespo.com")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end

          context "when the nir does not match with the user in the db" do
            let!(:user) do
              create(
                :user,
                role: "demandeur", affiliation_number: "ISQCJQO",
                address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
                phone_number: "+33782605941", email: "hernan@crespa.com", nir: generate_random_nir,
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "fails to add the user to the org" do
              visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

              attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                          make_visible: true)

              expect(page).to have_content("Ajouter à cette organisation")

              ## it does not display the db attributes
              expect(page).to have_no_content("Crespa")
              expect(page).to have_no_content("+33782605941")
              expect(page).to have_no_content("hernan@crespa.com")
              expect(page).to have_content("Cresp")
              expect(page).to have_content("0620022002")
              expect(page).to have_content("hernan@crespo.com")

              click_button("Ajouter à cette organisation")

              # it did not add the user
              expect(page).to have_content("Ajouter à cette organisation")
              expect(page).to have_no_css("i.fas.fa-link")
              expect(page).to have_content(
                "Le bénéficiaire #{user.id} a les mêmes attributs mais un nir différent"
              )
            end
          end
        end

        context "when the user is in another org common with the agent in another department" do
          let!(:agent) { create(:agent, organisations: [organisation, other_org_from_other_department]) }
          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "department_internal_id matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          context "in the same department" do
            let!(:user) do
              create(
                :user,
                department_internal_id: "8383", last_name: "Crespa",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the user to the org" do
              visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

              attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                          make_visible: true)

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_css(
                "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
              )

              expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(user.reload.first_name).to eq("Hernan")
              expect(user.reload.last_name).to eq("Crespo")
              expect(user.reload.affiliation_number).to eq("ISQCJQO")
              expect(user.reload.title).to eq("monsieur")
              expect(user.reload.role).to eq("demandeur")
              expect(user.reload.nir).to eq("180333147687266")
              expect(user.reload.email).to eq("hernan@crespo.com")
              expect(user.reload.phone_number).to eq("+33620022002")
              expect(user.reload.department_internal_id).to eq("8383")
            end
          end
        end

        context "in another department" do
          let!(:user) do
            create(
              :user,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "email matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user, email: "hernan@crespo.com", first_name: "hernan",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user, email: "hernan@crespo.com", first_name: "hernan",
                     organisations: [other_org_from_other_department],
                     rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end
      end

      describe "phone number matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user, phone_number: "0620022002", first_name: "hernan",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user,
              phone_number: "0620022002", first_name: "hernan",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_organisation_upload_path(organisation, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/organisations/#{organisation.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end
      end
    end
  end

  ###################################
  ###################################

  context "at department level" do
    before { travel_to now }

    it "can create and invite user" do
      visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

      ### Upload

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_content("Civilité")

      expect(page).to have_content("Civilité")
      expect(page).to have_content("M")
      expect(page).to have_content("Prénom")
      expect(page).to have_content("Hernan")
      expect(page).to have_content("Nom")
      expect(page).to have_content("Crespo")
      expect(page).to have_content("Numéro CAF")
      expect(page).to have_content("ISQCJQO")
      expect(page).to have_content("Rôle")
      expect(page).to have_content("DEM")
      expect(page).to have_content("ID Editeur")
      expect(page).to have_content("8383")
      expect(page).to have_content("Email")
      expect(page).to have_content("hernan@crespo.com")
      expect(page).to have_content("Téléphone")
      expect(page).to have_content("0620022002")
      expect(page).to have_content("NIR")
      expect(page).to have_content("1803331476872")
      expect(page).to have_content("Création compte")
      expect(page).to have_button("Créer compte", disabled: false)
      expect(page).to have_content("Invitation SMS")
      expect(page).to have_button("Inviter par SMS", disabled: true)
      expect(page).to have_content("Invitation mail")
      expect(page).to have_button("Inviter par Email", disabled: true)
      expect(page).to have_content("Invitation courrier")
      expect(page).to have_button("Générer courrier", disabled: true)

      ### Create

      click_button("Créer compte")

      expect(page).to have_button("Inviter par SMS", disabled: false)
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
      expect(page).to have_no_button("Créer compte")

      user = User.last
      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_css("a[href=\"/departments/#{department.id}/users/#{user.id}\"]")

      expect(user.first_name).to eq("Hernan")
      expect(user.last_name).to eq("Crespo")
      expect(user.affiliation_number).to eq("ISQCJQO")
      expect(user.title).to eq("monsieur")
      expect(user.role).to eq("demandeur")
      expect(user.nir).to eq("180333147687266")
      expect(user.email).to eq("hernan@crespo.com")
      expect(user.phone_number).to eq("+33620022002")
      expect(user.department_internal_id).to eq("8383")

      ### Invite by sms

      click_button("Inviter par SMS")

      expect(page).to have_no_button("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).to have_css("i.fas.fa-redo-alt")
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)

      invitation = Invitation.last

      expect(invitation.format).to eq("sms")
      expect(invitation.user).to eq(user)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-invite by sms

      click_button(class: "reinvitation-sms")

      expect(page).to have_content("Une invitation sms a déjà été envoyée aujourd'hui à cet usager")
      click_button("OK")

      invitation = Invitation.last
      invitation.destroy!

      click_button(class: "reinvitation-sms")

      expect(page).to have_no_content("Une invitation sms a déjà été envoyée aujourd'hui à cet usager")
      expect(invitation.format).to eq("sms")
      expect(invitation.user).to eq(user)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-upload the file

      visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

      attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"), make_visible: true)

      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_no_button("Créer compte")
      expect(page).to have_no_button("Inviter par SMS")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).to have_css("i.fas.fa-redo-alt")

      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
    end

    describe "Bulk actions" do
      context "without errors" do
        it "can bulk create users" do
          visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

          attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                      make_visible: true)

          click_button("Actions pour toute la sélection")
          expect(page).to have_no_css("td i.fas.fa-link")

          expect do
            click_button("Créer comptes")
            expect(page).to have_css("td i.fas.fa-link")
          end.to change(User, :count).by(1)
        end

        it "can bulk invite" do
          visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

          attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                      make_visible: true)

          click_button("Actions pour toute la sélection")
          expect(page).to have_no_button("Réinviter par SMS")

          click_button("Inviter par sms")
          expect(page).to have_css("i.fas.fa-check")
          expect(page).to have_css("i.fas.fa-redo-alt")
        end
      end

      context "with errors" do
        context "in case of creneau availability returning false" do
          before do
            stub_request(
              :get,
              /#{Regexp.quote(ENV['RDV_SOLIDARITES_URL'])}\/api\/rdvinsertion\/invitations\/creneau_availability.*/
            ).to_return(status: 200, body: { "creneau_availability" => false }.to_json, headers: {})
          end

          it "highlights users with errors" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            click_button("Actions pour toute la sélection")
            expect(page).to have_no_css("td i.fas.fa-check")

            click_button("Inviter par sms")
            expect(page).to have_css("tr.table-danger")
          end
        end

        context "in case of invalid uploaded file" do
          it "highlights users with errors" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test_invalid.xlsx"),
                        make_visible: true)

            click_button("Actions pour toute la sélection")
            expect(page).to have_no_css("tr.table-danger")

            click_button("Créer comptes")
            expect(page).to have_css("tr.table-danger")
          end
        end
      end
    end

    describe "Category selection" do
      context "when no option is selected" do
        it "redirects to category selection" do
          visit new_department_upload_path(department)

          expect(page).to have_content("Aucune catégorie de suivi")
          expect(page).to have_content(motif_category.name)

          click_link(motif_category.name)

          expect(page).to have_content("Choisissez un fichier d'usagers")
          expect(page).to have_content(motif_category.name)
        end

        context "when no category is selected" do
          it "can create users without affecting a category" do
            visit new_department_upload_path(department)

            expect(page).to have_content("Aucune catégorie de suivi")
            expect(page).to have_content(motif_category.name)

            click_link("Aucune catégorie de suivi")

            expect(page).to have_content("Choisissez un fichier d'usagers")

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_button("Créer compte")
            expect(page).to have_no_content("Invitation SMS")
            expect(page).to have_no_content("Invitation mail")
            expect(page).to have_no_content("Invitation courrier")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            user = User.last
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )

            expect(user.first_name).to eq("Hernan")
            expect(user.last_name).to eq("Crespo")
            expect(user.affiliation_number).to eq("ISQCJQO")
            expect(user.title).to eq("monsieur")
            expect(user.role).to eq("demandeur")
            expect(user.nir).to eq("180333147687266")
            expect(user.email).to eq("hernan@crespo.com")
            expect(user.phone_number).to eq("+33620022002")
            expect(user.department_internal_id).to eq("8383")
            expect(user.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            # It did not add categories
            expect(user.motif_categories).to eq([])
          end
        end
      end
    end

    describe "Users matching" do
      describe "nir matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end
      end

      describe "uid (affiliation_number/role) matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org common with the agent" do
          let!(:agent) { create(:agent, organisations: [organisation, other_org_from_same_department]) }

          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO",
              address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
              phone_number: "+33782605941", email: "hernan@crespa.com",
              organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            ## it does not display the db attributes
            expect(page).to have_no_content("Crespa")
            expect(page).to have_no_content("+33782605941")
            expect(page).to have_no_content("hernan@crespa.com")
            expect(page).to have_content("Cresp")
            expect(page).to have_content("0620022002")
            expect(page).to have_content("hernan@crespo.com")

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end

          context "when the nir does not match with the user in the db" do
            let!(:user) do
              create(
                :user,
                role: "demandeur", affiliation_number: "ISQCJQO",
                address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
                phone_number: "+33782605941", email: "hernan@crespa.com", nir: generate_random_nir,
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "fails to add the user to the org" do
              visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

              attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                          make_visible: true)

              ## it does not display the db attributes
              expect(page).to have_no_content("Crespa")
              expect(page).to have_no_content("+33782605941")
              expect(page).to have_no_content("hernan@crespa.com")
              expect(page).to have_content("Cresp")
              expect(page).to have_content("0620022002")
              expect(page).to have_content("hernan@crespo.com")

              expect(page).to have_content("Ajouter à cette organisation")

              click_button("Ajouter à cette organisation")

              # it did not add the user
              expect(page).to have_content("Ajouter à cette organisation")
              expect(page).to have_no_css("i.fas.fa-link")
              expect(page).to have_content(
                "Le bénéficiaire #{user.id} a les mêmes attributs mais un nir différent"
              )
            end
          end
        end

        context "when the user is in another org common with the agent in another department" do
          let!(:agent) { create(:agent, organisations: [organisation, other_org_from_other_department]) }
          let!(:user) do
            create(
              :user,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "department_internal_id matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          context "in the same department" do
            let!(:user) do
              create(
                :user,
                department_internal_id: "8383", last_name: "Crespa",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the user to the org" do
              visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

              attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                          make_visible: true)

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_css(
                "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
              )

              expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(user.reload.first_name).to eq("Hernan")
              expect(user.reload.last_name).to eq("Crespo")
              expect(user.reload.affiliation_number).to eq("ISQCJQO")
              expect(user.reload.title).to eq("monsieur")
              expect(user.reload.role).to eq("demandeur")
              expect(user.reload.nir).to eq("180333147687266")
              expect(user.reload.email).to eq("hernan@crespo.com")
              expect(user.reload.phone_number).to eq("+33620022002")
              expect(user.reload.department_internal_id).to eq("8383")
            end
          end
        end

        context "in another department" do
          let!(:user) do
            create(
              :user,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "email matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user, email: "hernan@crespo.com", first_name: "hernan",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user, email: "hernan@crespo.com", first_name: "hernan",
                     organisations: [other_org_from_other_department],
                     rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:user) do
            create(
              :user, email: "hernan@crespo.com", first_name: "lionel",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "phone number matching" do
        context "when the user is in the same org" do
          let!(:user) do
            create(
              :user, phone_number: "0620022002", first_name: "hernan",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the user page" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_no_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )
          end
        end

        context "when the user is in another org" do
          let!(:user) do
            create(
              :user, phone_number: "0620022002", first_name: "hernan",
                     organisations: [other_org_from_other_department],
                     rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the user to the org" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_css(
              "a[href=\"/departments/#{department.id}/users/#{user.id}\"]"
            )

            expect(user.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(user.reload.first_name).to eq("Hernan")
            expect(user.reload.last_name).to eq("Crespo")
            expect(user.reload.affiliation_number).to eq("ISQCJQO")
            expect(user.reload.title).to eq("monsieur")
            expect(user.reload.role).to eq("demandeur")
            expect(user.reload.nir).to eq("180333147687266")
            expect(user.reload.email).to eq("hernan@crespo.com")
            expect(user.reload.phone_number).to eq("+33620022002")
            expect(user.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:user) do
            create(
              :user, phone_number: "0620022002", first_name: "lionel",
                     organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the user" do
            visit new_department_upload_path(department, category_configuration_id: category_configuration.id)

            attach_file("users-list-upload", Rails.root.join("spec/fixtures/fichier_usager_test.xlsx"),
                        make_visible: true)

            expect(page).to have_content("Créer compte")
          end
        end
      end
    end
  end
end
