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

  let!(:invitation) do
    build(
      :invitation,
      user: user,
      follow_up: build(:follow_up, motif_category: category_orientation),
      organisations: [organisation]
    )
  end

  let!(:user) do
    create(:user, organisations: [organisation])
  end

  let!(:organisation) do
    create(:organisation, motifs: [motif])
  end

  let!(:configuration) do
    create(:configuration, organisation: organisation, motif_category: category_orientation)
  end

  let!(:motif) do
    create(:motif, motif_category: category_orientation)
  end

  let!(:department) do
    create(:department, organisations: [organisation], invitations: [invitation])
  end

  describe "#call" do
    it("is_a_success") do
      is_a_success
    end

    context "when the organisation phone number is missing" do
      before do
        organisation.update!(phone_number: nil)
        invitation.update(help_phone_number: nil)
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
      let!(:configuration) do
        create(:configuration, organisation: organisation, motif_category: category_accompagnement)
      end

      it("is a failure") { is_a_failure }

      it "stores an error message" do
        expect(subject.errors).to include(
          "L'usager n'appartient pas à une organisation qui gère la catégorie RSA orientation"
        )
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
