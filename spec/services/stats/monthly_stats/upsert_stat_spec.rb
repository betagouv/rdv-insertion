describe Stats::MonthlyStats::UpsertStat, type: :service do
  subject do
    described_class.call(structure_type: structure_type, structure_id: structure_id,
                         until_date_string: until_date_string)
  end

  let!(:department) { create(:department, created_at: Time.zone.parse("2022-01-17 12:00:00 +0100")) }
  let!(:until_date_string) { "2022-05-01 12:00:00 +0100" }
  let!(:date) { until_date_string.to_date }
  let!(:stats_values) do
    {
      users_count_grouped_by_month: 1,
      rdvs_count_grouped_by_month: 2,
      sent_invitations_count_grouped_by_month: 3,
      rate_of_no_show_for_invitations_grouped_by_month: 4,
      rate_of_no_show_for_convocations_grouped_by_month: 9,
      average_time_between_invitation_and_rdv_in_days_by_month: 5,
      rate_of_users_oriented_in_less_than_30_days_by_month: 7,
      rate_of_autonomous_users_grouped_by_month: 8
    }
  end
  let!(:stat) { create(:stat, statable_type: "Department", statable_id: department.id) }
  let!(:structure_type) { "Department" }
  let!(:structure_id) { department.id }

  describe "#call" do
    before do
      allow(Stats::MonthlyStats::ComputeForFocusedMonth).to receive(:call)
        .and_return(OpenStruct.new(success?: true, stats_values: stats_values))
      allow(Stat).to receive(:find_or_initialize_by)
        .and_return(stat)
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    context "when department" do
      it "finds or initializes stat record" do
        expect(Stat).to receive(:find_or_initialize_by)
          .with(statable_type: "Department", statable_id: department.id)
        subject
      end
    end

    context "when organisation" do
      let!(:organisation) { create(:organisation) }
      let!(:structure_type) { "Organisation" }
      let!(:structure_id) { organisation.id }

      it "finds or initializes stat record" do
        expect(Stat).to receive(:find_or_initialize_by)
          .with(statable_type: "Organisation", statable_id: organisation.id)
        subject
      end
    end

    it "calls the compute stats service" do
      expect(Stats::MonthlyStats::ComputeForFocusedMonth).to receive(:call)
        .exactly(4).times
      subject
    end

    it "computes the monthly stats" do
      subject
      expect(stat.reload[:users_count_grouped_by_month]).to eq(
        { "01/2022" => 1, "02/2022" => 1, "03/2022" => 1, "04/2022" => 1 }
      )
      expect(stat.reload[:rdvs_count_grouped_by_month]).to eq(
        { "01/2022" => 2, "02/2022" => 2, "03/2022" => 2, "04/2022" => 2 }
      )
      expect(stat.reload[:sent_invitations_count_grouped_by_month]).to eq(
        { "01/2022" => 3, "02/2022" => 3, "03/2022" => 3, "04/2022" => 3 }
      )
      expect(stat.reload[:rate_of_no_show_for_invitations_grouped_by_month]).to eq(
        { "01/2022" => 4, "02/2022" => 4, "03/2022" => 4, "04/2022" => 4 }
      )
      expect(stat.reload[:rate_of_no_show_for_convocations_grouped_by_month]).to eq(
        { "01/2022" => 9, "02/2022" => 9, "03/2022" => 9, "04/2022" => 9 }
      )
      expect(stat.reload[:average_time_between_invitation_and_rdv_in_days_by_month]).to eq(
        { "01/2022" => 5, "02/2022" => 5, "03/2022" => 5, "04/2022" => 5 }
      )
      expect(stat.reload[:rate_of_users_oriented_in_less_than_30_days_by_month]).to eq(
        { "01/2022" => 7, "02/2022" => 7, "03/2022" => 7, "04/2022" => 7 }
      )
      expect(stat.reload[:rate_of_autonomous_users_grouped_by_month]).to eq(
        { "01/2022" => 8, "02/2022" => 8, "03/2022" => 8, "04/2022" => 8 }
      )
    end

    it "saves a stat record" do
      expect(stat).to receive(:save)
      subject
    end
  end
end
