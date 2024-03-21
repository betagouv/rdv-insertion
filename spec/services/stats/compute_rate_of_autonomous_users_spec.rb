describe Stats::ComputeRateOfAutonomousUsers, type: :service do
  subject { described_class.call(users: users) }

  let(:date) { Time.zone.parse("17/03/2022 12:00") }

  let!(:users) { User.where(id: [user1, user2, user3, user4]) }
  let!(:rdvs) { Rdv.where(id: [rdv1, rdv2, rdv3]) }

  # First user : created 1 month ago, has a rdv taken in autonomy
  let!(:user1) { create(:user, created_at: date) }
  let!(:invitation1) do
    create(:invitation, created_at: date, follow_up: follow_up1, user: user1)
  end
  let!(:follow_up1) { create(:follow_up, created_at: date, user: user1) }
  let!(:rdv1) { create(:rdv, created_at: date, created_by: "user") }
  let!(:participation1) do
    create(:participation, follow_up: follow_up1, user: user1, rdv: rdv1, created_at: date)
  end

  # Second user : created 1 month ago, has a rdv not taken in autonomy
  let!(:user2) { create(:user, created_at: date) }
  let!(:invitation2) do
    create(:invitation, created_at: date, follow_up: follow_up2, user: user2)
  end
  let!(:follow_up2) { create(:follow_up, created_at: date, user: user2) }
  let!(:rdv2) { create(:rdv, created_at: date, created_by: "agent") }
  let!(:participation2) do
    create(:participation, follow_up: follow_up2, user: user2, rdv: rdv2, created_at: date)
  end

  # Third user : created 1 month ago, has a participation to a rdv taken in autonomy
  let!(:user3) { create(:user, created_at: date) }
  let!(:invitation3) do
    create(:invitation, created_at: date, follow_up: follow_up3, user: user3)
  end
  let!(:follow_up3) { create(:follow_up, created_at: date, user: user3) }
  let!(:rdv3) { create(:rdv, created_at: date, created_by: "agent") }
  let!(:participation3) do
    create(:participation, follow_up: follow_up3, user: user3,
                           rdv: rdv3, created_at: date, created_by: "user")
  end

  # Fourth user : created 1 month ago, has been invited but has not take any rdv
  let!(:user4) { create(:user, created_at: date) }
  let!(:invitation4) do
    create(:invitation, created_at: date, follow_up: follow_up4, user: user4)
  end
  let!(:follow_up4) { create(:follow_up, created_at: date, user: user4) }

  describe "#call" do
    let!(:result) { subject }

    it "is a success" do
      expect(result.success?).to eq(true)
    end

    it "renders a float" do
      expect(result.value).to be_a(Float)
    end

    # User 1 and 3 are ok ; 2 and 5 are not ok ; 4 is not considered
    it "computes the percentage of invited users with at least on participation to rdv taken in autonomy" do
      expect(result.value).to eq(50)
    end
  end
end
