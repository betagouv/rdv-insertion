describe DeleteRdvJob do
  subject do
    described_class.new.perform(rdv_solidarites_rdv_id)
  end

  let!(:rdv_solidarites_rdv_id) { { id: 1 } }
  let!(:rdv) { create(:rdv, participations: [create(:participation, follow_up: follow_up)]) }
  let!(:follow_up) { create(:follow_up) }

  describe "#perform" do
    before do
      rdv.reload
      allow(Rdv).to receive(:find_by)
        .with(rdv_solidarites_rdv_id: rdv_solidarites_rdv_id)
        .and_return(rdv)
      allow(rdv).to receive(:destroy!)
      allow(RefreshFollowUpStatusesJob).to receive(:perform_async)
    end

    it "finds the matching rdv" do
      expect(Rdv).to receive(:find_by)
        .with(rdv_solidarites_rdv_id: rdv_solidarites_rdv_id)
      subject
    end

    it "destroys the rdv" do
      expect(rdv).to receive(:destroy!)
      subject
    end

    it "enqueues a refresh status job" do
      expect(RefreshFollowUpStatusesJob).to receive(:perform_async)
        .with([follow_up.id])
      subject
    end
  end
end
