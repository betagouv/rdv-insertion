describe FollowUps::Close, type: :service do
  subject { described_class.call(follow_up: follow_up) }

  let!(:follow_up) { create(:follow_up) }
  let!(:invitation1) { create(:invitation, follow_up: follow_up) }
  let!(:invitation2) { create(:invitation, follow_up: follow_up) }

  describe "#call" do
    before do
      travel_to(Time.zone.parse("2023-05-04 12:30"))
      allow(InvalidateInvitationJob).to receive(:perform_async)
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    it "saves the closed_at date" do
      subject
      expect(follow_up.closed_at.strftime("%d/%m/%Y")).to eq("04/05/2023")
    end

    it "calls the InvalidateInvitationJob for the users invitations" do
      expect(InvalidateInvitationJob).to receive(:perform_async).exactly(1).time.with(invitation1.id)
      expect(InvalidateInvitationJob).to receive(:perform_async).exactly(1).time.with(invitation2.id)
      subject
    end

    context "when the user cannot be updated" do
      before do
        allow(follow_up).to receive(:save)
          .and_return(false)
        allow(follow_up).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("some error")
      end

      it "is a failure" do
        expect(subject.success?).to eq(false)
      end

      it "stores the error" do
        expect(subject.errors).to eq(["some error"])
      end

      it "does not call the InvalidateInvitationJob" do
        expect(InvalidateInvitationJob).not_to receive(:perform_async)
        subject
      end
    end
  end
end
