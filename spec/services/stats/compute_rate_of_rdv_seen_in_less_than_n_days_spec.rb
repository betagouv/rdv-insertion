describe Stats::ComputeRateOfRdvSeenInLessThanNDays, type: :service do
  describe "for 30 days" do
    subject { described_class.call(follow_ups: follow_ups, number_of_days: 30) }

    let(:created_at) { Time.zone.parse("17/03/2022 12:00") }
    let!(:now) { Time.zone.parse("25/04/2022 12:00") }

    let!(:follow_ups) { FollowUp.where(id: [follow_up1, follow_up2, follow_up3, follow_up4]) }

    # First case : created > 1 month ago, has a rdv_seen_delay_in_days present and the delay is less than 30 days
    # => considered as oriented in less than 30 days
    let!(:follow_up1) { create(:follow_up, created_at:) }
    let!(:rdv1) { create(:rdv, created_at:, starts_at: (created_at + 2.days), status: "seen") }
    let!(:participation1) do
      create(:participation, follow_up: follow_up1, rdv: rdv1, created_at:, status: "seen")
    end

    # Second case : created > 1 month ago, has a rdv_seen_delay_in_days present and the delay is more than 30 days
    # => not considered as oriented in less than 30 days
    let!(:follow_up2) { create(:follow_up, created_at:) }
    let!(:rdv2) { create(:rdv, created_at:, starts_at: (created_at + 33.days), status: "seen") }
    let!(:participation2) do
      create(:participation, follow_up: follow_up2, rdv: rdv2, created_at:, status: "seen")
    end

    # Third case : created > 1 month ago, has no rdv_seen_delay_in_days
    # => not considered as oriented in less than 30 days
    let!(:follow_up3) { create(:follow_up, created_at:) }

    # Fourth case : everything okay but created less than 30 days ago
    # not taken into account in the computing
    let!(:follow_up4) { create(:follow_up, created_at: 20.days.ago) }
    let!(:rdv4) { create(:rdv, created_at: 17.days.ago, starts_at: 15.days.ago, status: "seen") }
    let!(:participation4) do
      create(:participation, follow_up: follow_up4, rdv: rdv4, created_at: 17.days.ago, status: "seen")
    end

    before do
      travel_to(now)
    end

    describe "#call" do
      let!(:result) { subject }

      it "is a success" do
        expect(result.success?).to eq(true)
      end

      it "renders a float" do
        expect(result.value).to be_a(Float)
      end

      it "computes the percentage of follow_ups with rdv seen in less than 30 days" do
        expect(result.value).to eq(33.33333333333333)
      end
    end
  end

  describe "for 15 days" do
    subject { described_class.call(follow_ups:, number_of_days: 15) }

    let(:created_at) { Time.zone.parse("17/03/2022 12:00") }
    let!(:now) { Time.zone.parse("10/04/2022 12:00") }

    let!(:follow_ups) { FollowUp.where(id: [follow_up1, follow_up2, follow_up3, follow_up4]) }

    # First case : created > 15 days ago, has a rdv_seen_delay_in_days present and the delay is less than 30 days
    # => considered as oriented in less than 15 days
    let!(:follow_up1) { create(:follow_up, created_at:) }
    let!(:rdv1) { create(:rdv, created_at:, starts_at: (created_at + 2.days), status: "seen") }
    let!(:participation1) do
      create(:participation, follow_up: follow_up1, rdv: rdv1, created_at:, status: "seen")
    end

    # Second case : created > 15 days ago, has a rdv_seen_delay_in_days present and the delay is more than 15 days
    # => not considered as oriented in less than 15 days
    let!(:follow_up2) { create(:follow_up, created_at:) }
    let!(:rdv2) { create(:rdv, created_at:, starts_at: (created_at + 16.days), status: "seen") }
    let!(:participation2) do
      create(:participation, follow_up: follow_up2, rdv: rdv2, created_at:, status: "seen")
    end

    # Third case : created > 15 days ago, has no rdv_seen_delay_in_days present
    # => not considered as oriented in less than 15 days
    let!(:follow_up3) { create(:follow_up, created_at:) }

    # Fourth case : everything okay but created less than 15 days ago
    # not taken into account in the computing
    let!(:follow_up4) { create(:follow_up, created_at: 10.days.ago) }
    let!(:rdv4) { create(:rdv, created_at: 7.days.ago, starts_at: 3.days.ago, status: "seen") }
    let!(:participation4) do
      create(:participation, follow_up: follow_up4, rdv: rdv4, created_at: 7.days.ago, status: "seen")
    end

    before do
      travel_to(now)
    end

    describe "#call" do
      let!(:result) { subject }

      it "is a success" do
        expect(result.success?).to eq(true)
      end

      it "renders a float" do
        expect(result.value).to be_a(Float)
      end

      it "computes the percentage of follow_ups with rdv seen in less than 15 days" do
        expect(result.value).to eq(33.33333333333333)
      end
    end
  end
end
