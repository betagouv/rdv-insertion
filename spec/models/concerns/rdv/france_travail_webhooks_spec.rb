describe Rdv::FranceTravailWebhooks, type: :concern do
  let!(:organisation) do
    create(:organisation, safir_code: "123245", name: "CD de DIE")
  end
  let!(:rdv) do
    create(
      :rdv,
      id: 330, motif:, agents: [agent], created_by: "agent", duration_in_min: 30,
      starts_at:, lieu: create(:lieu, address: "105 Rue Camille Buffardel, Die, 26150"),
      organisation:, participations: [participation]
    )
  end
  let!(:participation) { create(:participation, user:) }

  let!(:starts_at) { Time.zone.parse("26/03/2024 16:15") }
  let!(:ends_at) { Time.zone.parse("26/03/2024 16:45") }
  let!(:birth_date) { Time.zone.parse("20/12/1987") }

  let!(:now) { Time.zone.parse("22/03/2024 14:22") }

  let!(:motif) do
    create(
      :motif,
      name: "RSA - Orientation : rdv sur site", collectif: false, location_type: "public_office",
      instruction_for_rdv: "ramener pièce identité"
    )
  end
  let!(:agent) do
    create(:agent, first_name: "Amine", last_name: "DHOBB", email: "amine.dhobb@beta.gouv.fr")
  end
  let!(:user) do
    create(:user, last_name: "Kopke", first_name: "Andreas", title: "monsieur", phone_number: "+33664891033",
                  birth_date:, email: "andreas@kopke.com")
  end

  let!(:france_travail_payload) do
    { "idOrigine" => 330,
      "libelleStructure" => "CD de DIE",
      "codeSafir" => "123245",
      "objet" => "RSA - Orientation : rdv sur site",
      "nombrePlaces" => nil,
      "idModalite" => 3,
      "typeReception" => "Individuel",
      "dateRendezvous" => starts_at.to_datetime,
      "duree" => 30,
      "initiateur" => "agent",
      "address" => "105 Rue Camille Buffardel, Die, 26150",
      "conseiller" => [{ "email" => "amine.dhobb@beta.gouv.fr", "nom" => "DHOBB", "prenom" => "Amine" }],
      "participants" => [
        { "nir" => nil, "nom" => "Kopke", "prenom" => "Andreas", "civilite" => "monsieur",
          "email" => "andreas@kopke.com", "telephone" => "+33664891033", "dateNaissance" => birth_date.to_date }
      ],
      "information" => "ramener pièce identité",
      "dateAnnulation" => nil,
      "dateFinRendezvous" => ends_at.to_datetime,
      "mode" => "modification" }
  end

  before do
    allow(rdv).to receive(:updated_at).and_return(now)
    allow(OutgoingWebhooks::SendFranceTravailWebhookJob).to receive(:perform_async)
  end

  describe "#send_france_travail_webhook" do
    it "enqueues the job" do
      expect(OutgoingWebhooks::SendFranceTravailWebhookJob).to receive(:perform_async)
        .with(france_travail_payload, now)
      rdv.save
    end

    context "when the organisation is not france travail" do
      before { organisation.update! safir_code: nil }

      it "does not enqueue a job" do
        expect(OutgoingWebhooks::SendFranceTravailWebhookJob).not_to receive(:perform_async)
      end
    end
  end
end
