describe RdvContexts::Save do
  subject { described_class.call(rdv_context:) }

  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:organisation) { create(:organisation, category_configurations: [category_configuration]) }
  let!(:category_configuration) { create(:category_configuration, motif_category: motif_category) }
  let!(:motif_category) { create(:motif_category) }
  let!(:rdv_context) { build(:rdv_context, user: user, motif_category: motif_category) }

  describe "#call" do
    it "is a success" do
      is_a_success
    end

    context "when the user does not belong to an organisation with this motif category" do
      let!(:category_configuration) { create(:category_configuration, motif_category: other_motif_category) }
      let!(:other_motif_category) { create(:motif_category, short_name: "rsa_accompagnement") }

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(
          ["L'usager n'appartient à aucune organisation gérant cette catégorie de motifs"]
        )
      end
    end

    it "creates a rdv context" do
      expect { subject }.to change(RdvContext, :count).by(1)
    end

    it "returns the rdv context" do
      expect(subject.rdv_context).to eq(RdvContext.last)
    end
  end
end
