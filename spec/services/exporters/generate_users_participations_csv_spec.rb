describe Exporters::GenerateUsersParticipationsCsv, type: :service do
  subject { described_class.call(user_ids: users.ids, structure: structure, motif_category: motif_category, agent:) }

  let!(:now) { Time.zone.parse("22/06/2022") }
  let!(:timestamp) { now.to_i }
  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", name: "RSA orientation") }
  let!(:department) { create(:department, name: "Drôme", number: "26") }
  let!(:organisation) { create(:organisation, name: "Drome RSA", department: department) }
  let!(:organisation_prescripteur) { create(:organisation, name: "Ailleurs", department: department) }
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
      address: "20 avenue de Ségur 75OO7 Paris",
      phone_number: "+33610101010",
      birth_date: "20/12/1977",
      rights_opening_date: "18/05/2022",
      created_at: "20/05/2022",
      role: "demandeur",
      organisations: [organisation],
      referents: [referent]
    )
  end
  let(:user2) { create(:user, last_name: "Casubolo", organisations: [organisation]) }
  let(:user3) { create(:user, last_name: "Blanc", organisations: [organisation]) }
  let!(:agent) { create(:agent, organisations: [organisation]) }
  let!(:agent_prescripteur) do
    create(:agent, first_name: "Georges", last_name: "Prescipteur", email: "g@prescripteur.fr",
                   rdv_solidarites_agent_id: 123,
                   organisations: [organisation_prescripteur])
  end

  let!(:rdv) do
    create(:rdv, starts_at: Time.zone.parse("2022-05-25"),
                 created_by: "user",
                 organisation: organisation,
                 participations: [participation_rdv])
  end
  let!(:participation_rdv) { create(:participation, user: user1, status: "seen") }

  let!(:rdv_prescrit) do
    create(:rdv, starts_at: Time.zone.parse("2022-05-25"),
                 created_by: "agent",
                 organisation: organisation,
                 participations: [participation_rdv_prescrit])
  end
  let!(:participation_rdv_prescrit) do
    create(:participation, user: user2, status: "seen", rdv_solidarites_agent_prescripteur_id: 123)
  end
  let!(:first_invitation) do
    create(:invitation, user: user1, format: "email", created_at: Time.zone.parse("2022-05-21"))
  end
  let!(:last_invitation) do
    create(:invitation, user: user1, format: "email", created_at: Time.zone.parse("2022-05-22"))
  end
  let!(:notification) do
    create(:notification, participation: participation_rdv, format: "email", created_at: Time.zone.parse("2022-06-22"))
  end
  let!(:rdv_context) do
    create(
      :rdv_context, invitations: [first_invitation, last_invitation],
                    motif_category: motif_category, participations: [participation_rdv],
                    user: user1, status: "rdv_needs_status_update"
    )
  end
  let!(:referent) do
    create(:agent, email: "monreferent@gouv.fr")
  end

  let!(:users) { User.where(id: [user1, user2, user3]) }

  describe "#call" do
    before { travel_to(now) }

    context "it exports users to csv" do
      let!(:csv) { subject.csv }

      it "is a success" do
        expect(subject.success?).to eq(true)
      end

      it "generates a filename" do
        expect(subject.filename).to eq("Export_rdvs_rsa_orientation_organisation_drome_rsa.csv")
      end

      it "generates headers" do
        expect(csv).to start_with("\uFEFF")
        expect(csv).to include("Statut du rdv")
        expect(csv).to include("Date du RDV")
        expect(csv).to include("Heure du RDV")
        expect(csv).to include("Motif du RDV")
        expect(csv).to include("Nature du RDV")
        expect(csv).to include("RDV pris en autonomie ?")
        expect(csv).to include("Référent(s)")
        expect(csv).to include("Organisation du rendez-vous")
        expect(csv).to include("Civilité")
        expect(csv).to include("Nom")
        expect(csv).to include("Prénom")
        expect(csv).to include("Numéro CAF")
        expect(csv).to include("ID interne au département")
        expect(csv).to include("Numéro de sécurité sociale")
        expect(csv).to include("ID France Travail")
        expect(csv).to include("ID interne au département")
        expect(csv).to include("Email")
        expect(csv).to include("Téléphone")
        expect(csv).to include("Date de naissance")
        expect(csv).to include("Date de création")
        expect(csv).to include("Date d'entrée flux")
        expect(csv).to include("Rôle")
        expect(csv).to include("Rendez-vous prescrit ? (interne)")
        expect(csv).to include("Prénom du prescripteur (interne)")
        expect(csv).to include("Nom du prescripteur (interne)")
        expect(csv).to include("Mail du prescripteur (interne)")
        expect(csv).to include("Tags")
      end

      context "it exports all the concerned users" do
        it "generates one line for each participation" do
          expect(csv.scan(/(?=\n)/).count).to eq(3) # one line per participation + 1 line of headers
        end

        it "displays all participations" do
          expect(csv).to include("Doe")
          expect(csv).to include("Casubolo")
        end
      end

      context "it displays the right attributes" do
        let!(:users) { User.where(id: [user1]) }

        it "displays the users attributes" do
          expect(csv.scan(/(?=\n)/).count).to eq(2) # we check there is only one user for this test
          expect(csv).to include("madame")
          expect(csv).to include("Doe")
          expect(csv).to include("Jane")
          expect(csv).to include("12345") # affiliation_number
          expect(csv).to include("33333") # department_internal_id
          expect(csv).to include(nir)
          expect(csv).to include("DDAAZZ") # france_travail_id
          expect(csv).to include("20 avenue de Ségur 75OO7 Paris")
          expect(csv).to include("jane@doe.com")
          expect(csv).to include("+33610101010")
          expect(csv).to include("20/12/1977") # birth_date
          expect(csv).to include("20/05/2022") # created_at
          expect(csv).to include("18/05/2022") # rights_opening_date
          expect(csv).to include("demandeur") # role
        end

        it "displays the rdv infos" do
          expect(csv).to include("25/05/2022") # rdv date
          expect(csv).to include("0h00") # rdv time
          expect(csv).to include("RSA orientation sur site") # rdv motif
          expect(csv).to include("individuel") # rdv type
          expect(csv).to include("individuel;Oui") # rdv taken in autonomy ?
          expect(csv).to include("Rendez-vous honoré") # rdv status
        end

        it "displays the organisation infos" do
          expect(csv).to include("1")
          expect(csv).to include(participation_rdv.organisation.name)
        end

        it "displays the referent emails" do
          expect(csv).to include("monreferent@gouv.fr")
        end
      end

      context "it displays the right attributes for a prescribed participation row" do
        let!(:users) { User.where(id: [user2]) }

        it "displays the prescripteur attributes" do
          expect(csv.scan(/(?=\n)/).count).to eq(2) # we check there is only one user for this test
          expect(csv).to include("Casubolo")
          expect(csv).to include("oui")
          expect(csv).to include("Georges")
          expect(csv).to include("Prescipteur")
          expect(csv).to include("g@prescripteur.fr")
        end
      end

      context "when no motif category is passed" do
        subject { described_class.call(user_ids: users.ids, structure: structure, motif_category: nil, agent:) }

        it "is a success" do
          expect(subject.success?).to eq(true)
        end

        it "generates the right filename" do
          expect(subject.filename).to eq("Export_rdvs_organisation_drome_rsa.csv")
        end

        it "generates headers" do
          expect(csv).to start_with("\uFEFF")
          expect(csv).not_to include("Statut de la catégorie de motifs")
        end
      end
    end
  end
end
