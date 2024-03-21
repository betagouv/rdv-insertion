describe FollowUps::Save do
  subject { described_class.call(follow_up:) }

  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:organisation) { create(:organisation, configurations: [configuration]) }
  let!(:configuration) { create(:configuration, motif_category: motif_category) }
  let!(:motif_category) { create(:motif_category) }
  let!(:follow_up) { build(:follow_up, user: user, motif_category: motif_category) }

  describe "#call" do
    it "is a success" do
      is_a_success
    end

    context "when the user does not belong to an organisation with this motif category" do
      let!(:configuration) { create(:configuration, motif_category: other_motif_category) }
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

    it "creates a follow-up" do
      expect { subject }.to change(FollowUp, :count).by(1)
    end

    it "returns the follow-up" do
      expect(subject.follow_up).to eq(FollowUp.last)
    end
  end
end
