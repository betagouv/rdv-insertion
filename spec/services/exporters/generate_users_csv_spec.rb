describe Exporters::GenerateUsersCsv, type: :service do
  subject { described_class.call(user_ids: users.ids, structure:, motif_category_id: motif_category.id, agent:) }

  let!(:now) { Time.zone.parse("22/06/2022") }
  let!(:timestamp) { now.to_i }
  let!(:motif_category) do
    create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation", leads_to_orientation: true)
  end
  let!(:department) { create(:department, name: "Drôme", number: "26") }
  let!(:organisation) { create(:organisation, name: "Drome RSA", department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:structure) { organisation }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: motif_category)
  end
  let!(:nir) { generate_random_nir }
  let!(:user1) do
    create(
      :user,
      first_name: "Jane",
      last_name: "Doe",
      title: "madame",
      affiliation_number: "12345",
      department_internal_id: "33333",
      nir: nir,
      france_travail_id: "DDAAZZ",
      email: "jane@doe.com",
      address: "20 avenue de Ségur paris",
      phone_number: "+33610101010",
      birth_date: "20/12/1977",
      rights_opening_date: "18/05/2022",
      created_at: "20/05/2022",
      role: "demandeur",
      organisations: [organisation],
      referents: [referent]
    )
  end
  let!(:address_geocoding) { create(:address_geocoding, user: user1, post_code: "75007", city: "Paris") }
  let(:user2) { create(:user, last_name: "Casubolo", organisations: [organisation]) }
  let(:user3) { create(:user, last_name: "Blanc", organisations: [organisation]) }

  let!(:rdv) do
    create(:rdv, starts_at: Time.zone.parse("2022-05-25"),
                 created_by: "user",
                 organisation:,
                 participations: [participation_rdv])
  end

  let!(:participation_rdv) { create(:participation, user: user1, status: "seen", created_at: "2022-05-20") }

  let!(:first_invitation) do
    create(:invitation, user: user1, format: "email", created_at: Time.zone.parse("2022-05-21"))
  end
  let!(:last_invitation) do
    create(:invitation, user: user1, format: "email", created_at: Time.zone.parse("2022-05-22"))
  end
  let!(:notification) do
    create(:notification, participation: participation_rdv, format: "email", created_at: Time.zone.parse("2022-06-22"))
  end
  let!(:follow_up) do
    create(
      :follow_up, invitations: [first_invitation, last_invitation],
                  motif_category: motif_category, participations: [participation_rdv],
                  user: user1, status: "rdv_needs_status_update",
                  created_at: Time.zone.parse("2022-05-08")
    )
  end
  let!(:referent) do
    create(:agent, email: "monreferent@gouv.fr")
  end

  let!(:users) { User.where(id: [user1, user2, user3]) }

  describe "#call" do
    before { travel_to(now) }

    context "it exports users to csv" do
      it "is a success" do
        expect(subject.success?).to eq(true)
      end

      it "generates a filename" do
        expect(subject.filename).to eq("Export_usagers_rsa_orientation_organisation_drome_rsa.csv")
      end

      it "generates headers" do # rubocop:disable RSpec/ExampleLength
        expect(subject.csv).to start_with("\uFEFF")
        expect(subject.csv).to include("Civilité")
        expect(subject.csv).to include("Nom")
        expect(subject.csv).to include("Prénom")
        expect(subject.csv).to include("Numéro CAF")
        expect(subject.csv).to include("ID interne au département")
        expect(subject.csv).to include("ID France Travail")
        expect(subject.csv).to include("ID interne au département")
        expect(subject.csv).to include("Email")
        expect(subject.csv).to include("Téléphone")
        expect(subject.csv).to include("Adresse")
        expect(subject.csv).to include("CP")
        expect(subject.csv).to include("Ville")
        expect(subject.csv).to include("Date de naissance")
        expect(subject.csv).to include("Date de création")
        expect(subject.csv).to include("Date d'entrée flux")
        expect(subject.csv).to include("Rôle")
        expect(subject.csv).to include("Archivé le")
        expect(subject.csv).to include("Motif d'archivage")
        expect(subject.csv).to include("Statut du rdv")
        expect(subject.csv).to include("Statut de la catégorie de motifs")
        expect(subject.csv).to include("Première invitation envoyée le")
        expect(subject.csv).to include("Dernière invitation envoyée le")
        expect(subject.csv).to include("Dernière convocation envoyée le")
        expect(subject.csv).to include("Date du dernier RDV")
        expect(subject.csv).to include("Heure du dernier RDV")
        expect(subject.csv).to include("Motif du dernier RDV")
        expect(subject.csv).to include("Nature du dernier RDV")
        expect(subject.csv).to include("Dernier RDV pris en autonomie ?")
        expect(subject.csv).to include("Dernier RDV pris le")
        expect(subject.csv).to include("Rendez-vous d'orientation (RSA) honoré en - moins de 30 jours?")
        expect(subject.csv).to include("Rendez-vous d'orientation (RSA) honoré en - moins de 15 jours?")
        expect(subject.csv).to include("Date d'orientation")
        expect(subject.csv).to include("Type d'orientation")
        expect(subject.csv).to include("Date de début d'accompagnement")
        expect(subject.csv).to include("Date de fin d'accompagnement")
        expect(subject.csv).to include("Structure d'orientation")
        expect(subject.csv).to include("Référent(s)")
        expect(subject.csv).to include("Nombre d'organisations")
        expect(subject.csv).to include("Nom des organisations")
      end

      context "it exports all the concerned users" do
        it "generates one line for each user required" do
          expect(subject.csv.scan(/(?=\n)/).count).to eq(4) # one line per users + 1 line of headers
        end

        it "displays all the users" do
          expect(subject.csv).to include("Doe")
          expect(subject.csv).to include("Casubolo")
          expect(subject.csv).to include("Blanc")
        end
      end

      context "it displays the right attributes" do
        let!(:users) { User.where(id: [user1]) }

        it "displays the users attributes" do
          expect(subject.csv.scan(/(?=\n)/).count).to eq(2) # we check there is only one user for this test
          expect(subject.csv).to include("madame")
          expect(subject.csv).to include("Doe")
          expect(subject.csv).to include("Jane")
          expect(subject.csv).to include("12345") # affiliation_number
          expect(subject.csv).to include("33333") # department_internal_id
          expect(subject.csv).to include("DDAAZZ") # france_travail_id
          expect(subject.csv).to include("20 avenue de Ségur paris")
          expect(subject.csv).to include("75007")
          expect(subject.csv).to include("Paris")
          expect(subject.csv).to include("jane@doe.com")
          expect(subject.csv).to include("+33610101010")
          expect(subject.csv).to include("20/12/1977") # birth_date
          expect(subject.csv).to include("20/05/2022") # created_at
          expect(subject.csv).to include("18/05/2022") # rights_opening_date
          expect(subject.csv).to include("demandeur") # role
        end

        it "displays the invitations infos" do
          expect(subject.csv).to include("21/05/2022") # first invitation date
          expect(subject.csv).to include("22/05/2022") # last invitation date
          expect(subject.csv).not_to include("(Délai dépassé)") # invitation delay
        end

        it "displays the notifications infos" do
          expect(subject.csv).to include("22/06/2022") # last notification date
        end

        it "displays the rdvs infos" do
          expect(subject.csv).to include("25/05/2022") # last rdv date
          expect(subject.csv).to include("0h00") # last rdv time
          expect(subject.csv).to include("RSA orientation sur site") # last rdv motif
          expect(subject.csv).to include("individuel") # last rdv type
          expect(subject.csv).to include("individuel;Oui") # last rdv taken in autonomy ?
          expect(subject.csv).to include("Oui;20/05/2022") # participation creation date
          expect(subject.csv).to include("Rendez-vous honoré") # rdv status
          expect(subject.csv).to include("Statut du RDV à préciser") # follow_up status
          # oriented in less than 30 days ?; oriented in less than 15 days?
          expect(subject.csv).to include("Statut du RDV à préciser;Oui;Non")
          expect(subject.csv).to include("Statut du RDV à préciser;Oui;Non;25/05/2022") # orientation date
        end

        it "displays the organisation infos" do
          expect(subject.csv).to include("1")
          expect(subject.csv).to include("Drome RSA")
        end

        it "displays the referent emails" do
          expect(subject.csv).to include("monreferent@gouv.fr")
        end

        it "does not display the user nir" do
          expect(subject.csv).not_to include("Numéro de sécurité sociale")
          expect(subject.csv).not_to include(user1.nir)
        end

        context "when the user is archived" do
          let!(:archive) do
            create(
              :archive,
              user: user1,
              created_at: Time.zone.parse("2022-06-20"),
              organisation:,
              archiving_reason: "test"
            )
          end

          it "displays the archive infos" do
            expect(subject.csv).to include("20/06/2022") # archive status
            expect(subject.csv).to include("20/06/2022;test") # archive reason
          end
        end
      end

      context "when rdvs are in a different department" do
        let!(:rdv) do
          create(:rdv, starts_at: Time.zone.parse("2022-06-03"),
                       created_by: "user",
                       organisation: other_organisation,
                       participations: [participation_rdv])
        end

        let!(:other_department) { create(:department, name: "Gironde", number: "33") }

        let!(:other_organisation) { create(:organisation, name: "Gironde RSA", department: other_department) }

        it "does not take the other department rdvs into account" do
          expect(subject.csv).not_to include("03/06/2022")
        end
      end

      context "when the user belongs to organisations in different departments" do
        let!(:other_department) do
          create(:department, name: "Ain", number: "01")
        end
        let!(:other_organisation) { create(:organisation, name: "CD 01", department: other_department, users: [user1]) }

        it "displays the name of the organisations saying it is another department" do
          expect(subject.csv).to include("CD 01 (Organisation d'un autre départment : 01 - Ain)")
        end
      end

      context "when the user has multiple tags in different organisations" do
        let!(:tag) { create(:tag, value: "cacahuète", users: [user1], organisations: [organisation]) }
        let!(:other_tag) { create(:tag, value: "pistache", users: [user1], organisations: [other_organisation]) }
        let!(:other_organisation) { create(:organisation, department:, users: [user1]) }

        context "at organisation level" do
          it "displays the user organisation tags" do
            expect(subject.csv).to include("cacahuète")
            expect(subject.csv).not_to include("pistache")
          end
        end

        context "at department level" do
          let!(:structure) { department }
          let!(:other_organisation_with_agent) { create(:organisation, department:, users: [user1]) }
          let!(:new_tag) do
            create(:tag, value: "chips", users: [user1], organisations: [other_organisation_with_agent])
          end
          let!(:agent) { create(:agent, organisations: [organisation, other_organisation_with_agent]) }

          it "displays the tags the agent has access to" do
            expect(subject.csv).to include("cacahuète")
            expect(subject.csv).not_to include("pistache")
            expect(subject.csv).to include("chips")
          end
        end
      end

      context "when last_rdv is not authorized for agent" do
        let!(:other_organisation) { create(:organisation, name: "Drome RSA", department: department) }

        let!(:rdv) do
          create(:rdv, starts_at: Time.zone.parse("2022-05-31"),
                       created_by: "user",
                       organisation: other_organisation,
                       participations: [participation_rdv])
        end

        context "if it is not the orientation date" do
          let!(:motif_category) do
            create(:motif_category, leads_to_orientation: false)
          end

          it "does not take it into account" do
            expect(subject.csv).not_to include("31/05/2022")
          end
        end

        context "if it is the orientation date" do
          it "is still displayed as the orientation date" do
            expect(subject.csv).to include("31/05/2022")
          end
        end
      end

      context "user has an orientation" do
        before do
          travel_to(Time.zone.parse("2024-06-10 11:00"))
        end

        let(:other_organisation) { create(:organisation, name: "Autre drome RSA", department:) }

        let!(:orientation) do
          create(:orientation,
                 user: user1,
                 orientation_type: create(:orientation_type, name: "Remobilisation renforcée"),
                 starts_at:,
                 ends_at:,
                 organisation: other_organisation)
        end

        let(:starts_at) { Time.zone.parse("2024-06-01") }
        let(:ends_at) { Time.zone.parse("2024-06-30") }

        it "displays the orientation infos" do
          expect(subject.csv).to include("Remobilisation renforcée") # orientation type
          expect(subject.csv).to include("01/06/2024") # orientation starts_at
          expect(subject.csv).to include("30/06/2024") # orientation ends_at
          expect(subject.csv).to include("Autre drome RSA") # orientation structure
        end

        context "orientation is inactive" do
          let(:starts_at) { Time.zone.parse("2022-06-01") }
          let(:ends_at) { Time.zone.parse("2022-06-30") }

          it "does not display the orientation infos" do
            expect(subject.csv).not_to include("Remobilisation renforcée")
            expect(subject.csv).not_to include("01/06/2022")
            expect(subject.csv).not_to include("30/06/2022")
            expect(subject.csv).not_to include("Autre drome RSA")
          end
        end
      end

      context "when the user is in many departments" do
        let!(:other_department) { create(:department, name: "Gironde", number: "33") }

        let!(:other_organisation) do
          create(:organisation, name: "Gironde RSA", department: other_department, users: [user1])
        end

        it "cannot calculate if the user has been oriented in less than X days" do
          expect(subject.csv).to include("Non calculable").twice
        end
      end

      context "when no motif category is passed" do
        subject { described_class.call(user_ids: users.ids, structure: structure, motif_category_id: nil, agent:) }

        it "is a success" do
          expect(subject.success?).to eq(true)
        end

        it "generates the right filename" do
          expect(subject.filename).to eq("Export_usagers_organisation_drome_rsa.csv")
        end

        it "generates headers" do
          expect(subject.csv).to start_with("\uFEFF")
          expect(subject.csv).not_to include("Statut de la catégorie de motifs")
        end
      end
    end
  end
end
