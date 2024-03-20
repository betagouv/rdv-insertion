describe Stats::MonthlyStats::UpsertStatJob do
  subject do
    described_class.new.perform("Department", department.id, until_date_string)
  end

  let!(:department) { create(:department) }
  let!(:until_date_string) { 1.month.ago.to_s }

  describe "#perform" do
    before do
      allow(Stats::MonthlyStats::UpsertStat).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    it "calls the appropriate service" do
      expect(Stats::MonthlyStats::UpsertStat).to receive(:call)
        .with(structure_type: "Department", structure_id: department.id, until_date_string: until_date_string)
      subject
    end

    context "when the service fails" do
      before do
        allow(Stats::MonthlyStats::UpsertStat).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["something happened"]))
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          ApplicationJob::FailedServiceError,
          "Calling service Stats::MonthlyStats::UpsertStat failed in Stats::MonthlyStats::UpsertStatJob:" \
          "\nErrors: [\"something happened\"]"
        )
      end
    end
  end
end
