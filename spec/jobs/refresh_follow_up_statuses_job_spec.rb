describe RefreshFollowUpStatusesJob do
  subject do
    described_class.new.perform(follow_up_ids)
  end

  let!(:follow_up_ids) { [23] }
  let!(:follow_up) { create(:follow_up) }

  describe "#perform" do
    before do
      allow(FollowUp).to receive_messages(includes: FollowUp, where: [follow_up])
      allow(follow_up).to receive(:set_status)
      allow(follow_up).to receive(:save!)
    end

    it "retrieves the users" do
      expect(FollowUp).to receive(:where)
        .with(id: follow_up_ids)
      subject
    end

    it "sets the status and saves" do
      expect(follow_up).to receive(:set_status)
      expect(follow_up).to receive(:save!)
      subject
    end
  end
end
