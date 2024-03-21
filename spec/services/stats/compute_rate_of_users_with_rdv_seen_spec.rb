describe Stats::ComputeRateOfUsersWithRdvSeen, type: :service do
  subject { described_class.call(follow_ups: follow_ups) }

  let!(:follow_ups) { FollowUp.where(id: [follow_up1, follow_up2, follow_up3, follow_up4]) }

  let!(:user1) { create(:user) }
  let!(:follow_up1) { create(:follow_up, user: user1, status: "rdv_seen") }
  let!(:rdv1) { create(:rdv, status: "seen") }
  let!(:participation1) { create(:participation, rdv: rdv1, follow_up: follow_up1, status: "seen") }

  let!(:user2) { create(:user) }
  let!(:follow_up2) { create(:follow_up, user: user2, status: "rdv_pending") }
  let!(:rdv2) { create(:rdv, status: "unknown") }
  let!(:participation2) { create(:participation, rdv: rdv2, follow_up: follow_up2, status: "unknown") }

  let!(:user3) { create(:user) }
  let!(:follow_up3) { create(:follow_up, user: user3, status: "rdv_noshow") }
  let!(:rdv3) { create(:rdv, status: "noshow") }
  let!(:participation3) { create(:participation, rdv: rdv3, follow_up: follow_up3, status: "noshow") }

  let!(:user4) { create(:user) }
  let!(:follow_up4) { create(:follow_up, user: user4, status: "not_invited") }

  describe "#call" do
    let!(:result) { subject }

    it "is a success" do
      expect(result.success?).to eq(true)
    end

    it "renders a float" do
      expect(result.value).to be_a(Float)
    end

    it "computes the percentage of users with rdv seen" do
      expect(result.value).to eq(25)
    end
  end
end
