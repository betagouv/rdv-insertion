describe Invitations::Validate, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  let!(:category_orientation) do
    create(:motif_category, name: "RSA orientation", short_name: "rsa_orientation")
  end
  let!(:category_accompagnement) do
    create(:motif_category, name: "RSA accompagnement", short_name: "rsa_accompagnement")
  end

  let!(:invitation) { build(:invitation, user: user, follow_up: follow_up, organisations: [organisation], department:) }

  let!(:user) do
    create(:user, organisations: [organisation])
  end

  let!(:follow_up) { create(:follow_up, user: user, motif_category: category_orientation) }

  let!(:participation) { create(:participation, follow_up: follow_up, user: user) }

  let!(:rdv) do
    create(:rdv, participations: [participation], status: "unknown", created_at: 3.days.ago, starts_at: 2.days.ago)
  end

  let!(:organisation) do
    create(:organisation, motifs: [motif])
  end

  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: category_orientation)
  end

  let!(:motif) do
    create(:motif, motif_category: category_orientation)
  end

  let!(:department) do
    create(:department, organisations: [organisation])
  end

  describe "#call" do
    it("is_a_success") do
      is_a_success
    end

    context "when the organisation phone number is missing" do
      before do
        organisation.update!(phone_number: nil)
        invitation.assign_attributes(help_phone_number: nil)
      end

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "Le téléphone de contact de l'organisation #{organisation.name} doit être indiqué."
        )
      end
    end

    context "when organisations are from different departments" do
      before { organisation.department = build(:department) }

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "Les organisations ne peuvent pas être liés à des départements différents de l'invitation"
        )
      end
    end

    context "when a participation is pending" do
      before do
        follow_up.reload
      end

      let!(:rdv) { create(:rdv, participations: [participation], status: "unknown", starts_at: 2.days.from_now) }

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "Cet usager a déjà un rendez-vous à venir pour ce motif"
        )
      end
    end

    context "when the user title is missing" do
      before { user.update! title: nil }

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "La civilité de la personne doit être précisée pour pouvoir envoyer une invitation"
        )
      end
    end

    context "when it is a postal invitation and the validity is < 5 days" do
      before { invitation.assign_attributes(format: "postal", valid_until: 2.days.from_now) }

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "La durée de validité de l'invitation pour un courrier doit être supérieure à 5 jours"
        )
      end
    end

    context "when the user does not belong to an org for that category" do
      let!(:category_configuration) do
        create(:category_configuration, organisation: organisation, motif_category: category_accompagnement)
      end

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "L'usager n'appartient pas ou n'est pas actif dans une organisation qui gère la catégorie RSA orientation"
        )
      end

      context "when the user is archived in the organisation that handles that category" do
        let!(:archive) { create(:archive, organisation:, user:) }

        it("is a failure") { is_a_failure }

        it "stores an error message" do
          expect(subject.errors).to include(
            "L'usager n'appartient pas ou n'est pas actif dans une organisation qui gère la catégorie RSA orientation"
          )
        end
      end
    end

    context "when there is no motif for that category on the organisations" do
      before { motif.update!(motif_category: category_accompagnement) }

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "Aucun motif de la catégorie RSA orientation n'est défini sur RDV-Solidarités"
        )
      end
    end

    context "when there is already a sent invitation today" do
      let!(:existing_invitation) { create(:invitation, format: "sms", created_at: 4.hours.ago, follow_up:) }

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to include("Une invitation sms a déjà été envoyée aujourd'hui à cet usager")
      end

      context "when the format is postal" do
        let!(:existing_invitation) { create(:invitation, format: "postal", created_at: 4.hours.ago, follow_up:) }

        it "is a success" do
          is_a_success
        end
      end
    end

    context "with referents" do
      before do
        invitation.rdv_with_referents = true
      end

      let!(:motif) { create(:motif, motif_category: category_orientation, follow_up: true) }
      let!(:agent) { create(:agent, users: [user]) }

      it "is_a_success" do
        is_a_success
      end

      context "when no referents is assigned" do
        let!(:agent) { create(:agent, users: []) }

        it("is a failure") { is_a_failure }

        it "stores an error message" do
          expect(subject.errors).to include(
            "Un référent doit être assigné au bénéficiaire pour les rdvs avec référents"
          )
        end
      end

      context "when no follow up motifs are defined for the category" do
        let!(:motif) { create(:motif, motif_category: category_orientation, follow_up: false) }

        it("is a failure") { is_a_failure }

        it "stores an error message" do
          expect(subject.errors).to include(
            "Aucun motif de suivi n'a été défini pour la catégorie RSA orientation"
          )
        end
      end
    end
  end
end
