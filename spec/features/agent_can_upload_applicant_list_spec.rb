describe "Agents can upload applicant list", js: true do
  include_context "with file configuration"

  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department,
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id,
      # needed for the organisation applicants page
      configurations: [configuration],
      slug: "org1"
    )
  end
  let!(:motif) { create(:motif, organisation: organisation, motif_category: motif_category) }

  let!(:configuration) do
    create(:configuration, motif_category: motif_category, file_configuration: file_configuration)
  end

  let!(:other_org_from_same_department) { create(:organisation, department: department) }
  let!(:other_department) { create(:department) }
  let!(:other_org_from_other_department) { create(:organisation, department: other_department) }

  let!(:now) { Time.zone.parse("05/10/2022") }

  let!(:motif_category) { create(:motif_category) }
  let!(:rdv_solidarites_user_id) { 2323 }
  let!(:rdv_solidarites_organisation_id) { 3234 }

  before do
    setup_agent_session(agent)
    stub_rdv_solidarites_create_user(rdv_solidarites_user_id)
    stub_rdv_solidarites_update_user(rdv_solidarites_user_id)
    stub_send_in_blue
    stub_rdv_solidarites_get_organisation_user(rdv_solidarites_organisation_id, rdv_solidarites_user_id)
    stub_rdv_solidarites_invitation_requests(rdv_solidarites_user_id)
    stub_geo_api_request("127 RUE DE GRENELLE 75007 PARIS")
  end

  context "at organisation level" do
    before { travel_to now }

    it "can create and invite applicant" do
      visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

      ### Upload

      attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

      expect(page).to have_content("Civilité")
      expect(page).to have_content("M")
      expect(page).to have_content("Prénom")
      expect(page).to have_content("Hernan")
      expect(page).to have_content("Nom")
      expect(page).to have_content("Crespo")
      expect(page).to have_content("Numéro allocataire")
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
      expect(page).to have_content("180333147687266")
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
      expect(page).not_to have_button("Créer compte")

      applicant = Applicant.last
      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_selector(:css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]")

      expect(applicant.first_name).to eq("Hernan")
      expect(applicant.last_name).to eq("Crespo")
      expect(applicant.affiliation_number).to eq("ISQCJQO")
      expect(applicant.title).to eq("monsieur")
      expect(applicant.role).to eq("demandeur")
      expect(applicant.nir).to eq("180333147687266")
      expect(applicant.email).to eq("hernan@crespo.com")
      expect(applicant.phone_number).to eq("+33620022002")
      expect(applicant.department_internal_id).to eq("8383")
      expect(applicant.address).to eq("127 RUE DE GRENELLE 75007 PARIS")

      ### Invite by sms

      click_button("Inviter par SMS")

      expect(page).to have_css("i.fas.fa-check")
      expect(page).not_to have_button("Inviter par SMS")
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)

      invitation = Invitation.last

      expect(invitation.format).to eq("sms")
      expect(invitation.applicant).to eq(applicant)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-upload the file

      visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

      attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

      expect(page).to have_css("i.fas.fa-link")
      expect(page).not_to have_button("Créer compte")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).not_to have_button("Inviter par SMS")

      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
    end

    describe "Applicants matching" do
      describe "nir matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              nir: "180333147687266", address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
              phone_number: "+33782605941", email: "hernan@crespa.com",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")

            ## it displays the db attributes
            expect(page).to have_content("Crespa")
            expect(page).to have_content("+33782605941")
            expect(page).to have_content("hernan@crespa.com")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end
      end

      describe "uid (affiliation_number/role) matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          context "in the same department" do
            let!(:applicant) do
              create(
                :applicant,
                role: "demandeur", affiliation_number: "ISQCJQO",
                address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
                phone_number: "+33782605941", email: "hernan@crespa.com",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the applicant to the org" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Ajouter à cette organisation")

              ## it does not display the db attributes
              expect(page).not_to have_content("Crespa")
              expect(page).not_to have_content("+33782605941")
              expect(page).not_to have_content("hernan@crespa.com")
              expect(page).to have_content("Cresp")
              expect(page).to have_content("0620022002")
              expect(page).to have_content("hernan@crespo.com")

              click_button("Ajouter à cette organisation")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
              )

              expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.last_name).to eq("Crespo")
              expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
              expect(applicant.reload.title).to eq("monsieur")
              expect(applicant.reload.role).to eq("demandeur")
              expect(applicant.reload.nir).to eq("180333147687266")
              expect(applicant.reload.email).to eq("hernan@crespo.com")
              expect(applicant.reload.phone_number).to eq("+33620022002")
              expect(applicant.reload.department_internal_id).to eq("8383")
            end
          end

          context "when the nir of does not match with the applicant in the db" do
            let!(:applicant) do
              create(
                :applicant,
                role: "demandeur", affiliation_number: "ISQCJQO",
                address: "20 avenue de ségur 75007 Paris", last_name: "Crespa",
                phone_number: "+33782605941", email: "hernan@crespa.com", nir: generate_random_nir,
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "fails to add the applicant to the org" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Ajouter à cette organisation")

              ## it does not display the db attributes
              expect(page).not_to have_content("Crespa")
              expect(page).not_to have_content("+33782605941")
              expect(page).not_to have_content("hernan@crespa.com")
              expect(page).to have_content("Cresp")
              expect(page).to have_content("0620022002")
              expect(page).to have_content("hernan@crespo.com")

              click_button("Ajouter à cette organisation")

              # it did not add the applicant
              expect(page).to have_content("Ajouter à cette organisation")
              expect(page).not_to have_css("i.fas.fa-link")
              expect(page).to have_content("La personne #{applicant.id} correspond mais n'a pas le même NIR")
            end
          end
        end

        context "in another department" do
          let!(:applicant) do
            create(
              :applicant,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "department_internal_id matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          context "in the same department" do
            let!(:applicant) do
              create(
                :applicant,
                department_internal_id: "8383", last_name: "Crespa",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the applicant to the org" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Ajouter à cette organisation")

              click_button("Ajouter à cette organisation")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
              )

              expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.last_name).to eq("Crespo")
              expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
              expect(applicant.reload.title).to eq("monsieur")
              expect(applicant.reload.role).to eq("demandeur")
              expect(applicant.reload.nir).to eq("180333147687266")
              expect(applicant.reload.email).to eq("hernan@crespo.com")
              expect(applicant.reload.phone_number).to eq("+33620022002")
              expect(applicant.reload.department_internal_id).to eq("8383")
            end
          end
        end

        context "in another department" do
          let!(:applicant) do
            create(
              :applicant,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "email matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant, email: "hernan@crespo.com", first_name: "hernan",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant, email: "hernan@crespo.com", first_name: "hernan",
                          organisations: [other_org_from_other_department],
                          rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:applicant) do
            create(
              :applicant,
              email: "hernan@crespo.com", address: "20 avenue de ségur 75007 Paris", first_name: "lionel",
              last_name: "crespo", role: nil,
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "offers a choice to create or to update the applicant" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_button("C'est la même personne")
            expect(page).to have_button("C'est une autre personne")

            click_button("Annuler")

            # it does not do anything
            expect(Applicant.count).to eq(1)
            expect(applicant.reload.first_name).to eq("lionel")
          end

          context "when we update the existing applicant" do
            it "updates the applicant" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_button("C'est la même personne")
              click_button("C'est la même personne")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
              )

              expect(page).to have_content("Hernan")
              expect(page).to have_content("180333147687266")

              expect(Applicant.count).to eq(1)
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.nir).to eq("180333147687266")
            end
          end

          context "when we create a new applicant" do
            before { stub_rdv_solidarites_create_user("some-id") }

            it "creates an applicant" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_button("C'est une autre personne")
              click_button("C'est une autre personne")

              expect(page).to have_content("Hernan")
              expect(page).to have_content("180333147687266")

              expect(Applicant.count).to eq(2)
              new_applicant = Applicant.last

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{new_applicant.id}\"]"
              )

              expect(new_applicant.email).to be_nil
              expect(new_applicant.first_name).to eq("Hernan")
              expect(new_applicant.nir).to eq("180333147687266")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{new_applicant.id}\"]"
              )

              # it did not modify existing applicant
              expect(applicant.reload.first_name).to eq("lionel")
              expect(applicant.reload.nir).to be_nil
            end
          end
        end
      end

      describe "phone number matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant, phone_number: "0620022002", first_name: "hernan",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant,
              phone_number: "0620022002", first_name: "hernan",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:applicant) do
            create(
              :applicant,
              phone_number: "0620022002", address: "20 avenue de ségur 75007 Paris", first_name: "lionel",
              role: nil,
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")

            click_button("Créer compte")

            expect(page).to have_button("C'est la même personne")
            expect(page).to have_button("C'est une autre personne")

            click_button("Annuler")

            # it does not do anything
            expect(Applicant.count).to eq(1)
            expect(applicant.reload.first_name).to eq("lionel")
          end

          context "when we update the existing applicant" do
            it "updates the applicant" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_button("C'est la même personne")
              click_button("C'est la même personne")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{applicant.id}\"]"
              )

              expect(page).to have_content("Hernan")
              expect(page).to have_content("180333147687266")

              expect(Applicant.count).to eq(1)
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.nir).to eq("180333147687266")
            end
          end

          context "when we create a new applicant" do
            # necessary to stub for another applicant so that it does not retrieve the same
            # rdv_solidarites_user_id
            before { stub_rdv_solidarites_create_user("some-id") }

            it "creates an applicant" do
              visit new_organisation_upload_path(organisation, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Créer compte")

              click_button("Créer compte")

              expect(page).to have_button("C'est une autre personne")
              click_button("C'est une autre personne")

              expect(page).to have_content("Hernan")
              expect(page).to have_content("180333147687266")

              expect(Applicant.count).to eq(2)
              new_applicant = Applicant.last

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{new_applicant.id}\"]"
              )

              expect(new_applicant.phone_number).to be_nil
              expect(new_applicant.first_name).to eq("Hernan")
              expect(new_applicant.nir).to eq("180333147687266")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/organisations/#{organisation.id}/applicants/#{new_applicant.id}\"]"
              )

              # it did not modify existing applicant
              expect(applicant.reload.first_name).to eq("lionel")
              expect(applicant.reload.nir).to be_nil
            end
          end
        end
      end
    end
  end

  ###################################
  ###################################

  context "at department level" do
    before { travel_to now }

    it "can create and invite applicant" do
      visit new_department_upload_path(department, configuration_id: configuration.id)

      ### Upload

      attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

      expect(page).to have_content("Civilité")

      expect(page).to have_content("Civilité")
      expect(page).to have_content("M")
      expect(page).to have_content("Prénom")
      expect(page).to have_content("Hernan")
      expect(page).to have_content("Nom")
      expect(page).to have_content("Crespo")
      expect(page).to have_content("Numéro allocataire")
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
      expect(page).to have_content("180333147687266")
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
      expect(page).not_to have_button("Créer compte")

      applicant = Applicant.last
      expect(page).to have_css("i.fas.fa-link")
      expect(page).to have_selector(:css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]")

      expect(applicant.first_name).to eq("Hernan")
      expect(applicant.last_name).to eq("Crespo")
      expect(applicant.affiliation_number).to eq("ISQCJQO")
      expect(applicant.title).to eq("monsieur")
      expect(applicant.role).to eq("demandeur")
      expect(applicant.nir).to eq("180333147687266")
      expect(applicant.email).to eq("hernan@crespo.com")
      expect(applicant.phone_number).to eq("+33620022002")
      expect(applicant.department_internal_id).to eq("8383")

      ### Invite by sms

      click_button("Inviter par SMS")

      expect(page).to have_css("i.fas.fa-check")
      expect(page).not_to have_button("Inviter par SMS")
      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)

      invitation = Invitation.last

      expect(invitation.format).to eq("sms")
      expect(invitation.applicant).to eq(applicant)
      expect(invitation.motif_category).to eq(motif_category)

      ### Re-upload the file

      visit new_department_upload_path(department, configuration_id: configuration.id)

      attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

      expect(page).to have_css("i.fas.fa-link")
      expect(page).not_to have_button("Créer compte")
      expect(page).to have_css("i.fas.fa-check")
      expect(page).not_to have_button("Inviter par SMS")

      expect(page).to have_button("Inviter par Email", disabled: false)
      expect(page).to have_button("Générer courrier", disabled: false)
    end

    describe "Applicants matching" do
      describe "nir matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant,
              nir: "180333147687266", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end
      end

      describe "uid (affiliation_number/role) matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          context "in the same department" do
            let!(:applicant) do
              create(
                :applicant,
                role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the applicant to the org" do
              visit new_department_upload_path(department, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Ajouter à cette organisation")

              click_button("Ajouter à cette organisation")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
              )

              expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.last_name).to eq("Crespo")
              expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
              expect(applicant.reload.title).to eq("monsieur")
              expect(applicant.reload.role).to eq("demandeur")
              expect(applicant.reload.nir).to eq("180333147687266")
              expect(applicant.reload.email).to eq("hernan@crespo.com")
              expect(applicant.reload.phone_number).to eq("+33620022002")
              expect(applicant.reload.department_internal_id).to eq("8383")
            end
          end
        end

        context "in another department" do
          let!(:applicant) do
            create(
              :applicant,
              role: "demandeur", affiliation_number: "ISQCJQO", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "department_internal_id matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          context "in the same department" do
            let!(:applicant) do
              create(
                :applicant,
                department_internal_id: "8383", last_name: "Crespa",
                organisations: [other_org_from_same_department], rdv_solidarites_user_id: rdv_solidarites_user_id
              )
            end

            it "can add the applicant to the org" do
              visit new_department_upload_path(department, configuration_id: configuration.id)

              attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

              expect(page).to have_content("Ajouter à cette organisation")

              click_button("Ajouter à cette organisation")

              expect(page).to have_css("i.fas.fa-link")
              expect(page).to have_selector(
                :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
              )

              expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
              expect(applicant.reload.first_name).to eq("Hernan")
              expect(applicant.reload.last_name).to eq("Crespo")
              expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
              expect(applicant.reload.title).to eq("monsieur")
              expect(applicant.reload.role).to eq("demandeur")
              expect(applicant.reload.nir).to eq("180333147687266")
              expect(applicant.reload.email).to eq("hernan@crespo.com")
              expect(applicant.reload.phone_number).to eq("+33620022002")
              expect(applicant.reload.department_internal_id).to eq("8383")
            end
          end
        end

        context "in another department" do
          let!(:applicant) do
            create(
              :applicant,
              department_internal_id: "8383", last_name: "Crespa",
              organisations: [other_org_from_other_department], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "email matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant, email: "hernan@crespo.com", first_name: "hernan",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant, email: "hernan@crespo.com", first_name: "hernan",
                          organisations: [other_org_from_other_department],
                          rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:applicant) do
            create(
              :applicant, email: "hernan@crespo.com", first_name: "lionel",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end

      describe "phone number matching" do
        context "when the applicant is in the same org" do
          let!(:applicant) do
            create(
              :applicant, phone_number: "0620022002", first_name: "hernan",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "displays the link to the applicant page" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).not_to have_content("Créer compte")
            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )
          end
        end

        context "when the applicant is in another org" do
          let!(:applicant) do
            create(
              :applicant, phone_number: "0620022002", first_name: "hernan",
                          organisations: [other_org_from_other_department],
                          rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "can add the applicant to the org" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Ajouter à cette organisation")

            click_button("Ajouter à cette organisation")

            expect(page).to have_css("i.fas.fa-link")
            expect(page).to have_selector(
              :css, "a[href=\"/departments/#{department.id}/applicants/#{applicant.id}\"]"
            )

            expect(applicant.reload.address).to eq("127 RUE DE GRENELLE 75007 PARIS")
            expect(applicant.reload.first_name).to eq("Hernan")
            expect(applicant.reload.last_name).to eq("Crespo")
            expect(applicant.reload.affiliation_number).to eq("ISQCJQO")
            expect(applicant.reload.title).to eq("monsieur")
            expect(applicant.reload.role).to eq("demandeur")
            expect(applicant.reload.nir).to eq("180333147687266")
            expect(applicant.reload.email).to eq("hernan@crespo.com")
            expect(applicant.reload.phone_number).to eq("+33620022002")
            expect(applicant.reload.department_internal_id).to eq("8383")
          end
        end

        context "when the first name is not the same" do
          let!(:applicant) do
            create(
              :applicant, phone_number: "0620022002", first_name: "lionel",
                          organisations: [organisation], rdv_solidarites_user_id: rdv_solidarites_user_id
            )
          end

          it "does not match the applicant" do
            visit new_department_upload_path(department, configuration_id: configuration.id)

            attach_file("file-upload", Rails.root.join("spec/fixtures/fichier_allocataire_test.xlsx"))

            expect(page).to have_content("Créer compte")
          end
        end
      end
    end
  end
end
