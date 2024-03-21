describe Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays, type: :service do
  subject { described_class.call(follow_ups: follow_ups) }

  let(:date) { Time.zone.parse("17/03/2022 12:00") }

  let!(:follow_ups) { FollowUp.where(id: [follow_up1, follow_up2]) }

  # First follow_up : 2 days delay between first invitation and first participation creation
  let!(:follow_up1) { create(:follow_up, created_at: date) }
  let!(:invitation1) { create(:invitation, created_at: date, follow_up: follow_up1) }
  let!(:participation1) do
    create(:participation, follow_up: follow_up1, created_at: (date + 2.days), status: "seen")
  end
  let!(:rdv1) { create(:rdv, created_at: (date + 2.days), participations: [participation1]) }

  # Second follow_up : 4 days delay between first invitation and first participation creation
  let!(:follow_up2) { create(:follow_up, created_at: date) }
  let!(:invitation2) { create(:invitation, created_at: date, follow_up: follow_up2) }
  let!(:participation2) do
    create(:participation, follow_up: follow_up2, created_at: (date + 4.days), status: "seen")
  end
  let!(:rdv2) { create(:rdv, created_at: (date + 4.days), participations: [participation2]) }

  describe "#call" do
    let!(:result) { subject }

    it "is a success" do
      expect(result.success?).to eq(true)
    end

    it "renders a float" do
      expect(result.value).to be_a(Float)
    end

    it "computes the average time between first invitation and first rdv in days" do
      expect(result.value).to eq(3)
    end

    context "negative values" do
      let!(:participation1) do
        create(:participation, follow_up: follow_up1, created_at: (date - 2.days), status: "seen")
      end
      let!(:rdv1) { create(:rdv, created_at: (date - 2.days), participations: [participation1]) }

      let!(:participation2) do
        create(:participation, follow_up: follow_up2, created_at: (date + 4.days), status: "seen")
      end
      let!(:rdv2) { create(:rdv, created_at: (date + 4.days), participations: [participation2]) }

      it "doesn't take into account negative values" do
        expect(result.value).to eq(4)
      end

      context "no positive values" do
        let!(:participation1) do
          create(:participation, follow_up: follow_up1, created_at: (date - 2.days), status: "seen")
        end
        let!(:rdv1) { create(:rdv, created_at: (date - 2.days), participations: [participation1]) }

        let!(:participation2) do
          create(:participation, follow_up: follow_up2, created_at: (date - 4.days), status: "seen")
        end
        let!(:rdv2) { create(:rdv, created_at: (date - 4.days), participations: [participation2]) }

        it "returns 0" do
          expect(result.value).to eq(0)
        end
      end
    end
  end
end
