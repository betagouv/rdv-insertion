describe Stats::GlobalStats::UpsertStatJob do
  subject do
    described_class.new.perform("Department", department.id)
  end

  let!(:department) { create(:department) }

  describe "#perform" do
    before do
      allow(Stats::GlobalStats::UpsertStat).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    it "calls the appropriate service" do
      expect(Stats::GlobalStats::UpsertStat).to receive(:call)
        .with(structure_type: "Department", structure_id: department.id)
      subject
    end

    context "when the service fails" do
      before do
        allow(Stats::GlobalStats::UpsertStat).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["something happened"]))
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          ApplicationJob::FailedServiceError,
          "Calling service Stats::GlobalStats::UpsertStat failed in Stats::GlobalStats::UpsertStatJob:" \
          "\nErrors: [\"something happened\"]"
        )
      end
    end
  end
end
