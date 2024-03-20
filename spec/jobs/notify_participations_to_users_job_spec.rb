describe NotifyParticipationsToUsersJob do
  subject do
    described_class.new.perform(participation_ids, event_to_notify)
  end

  let!(:rdv_id) { 2213 }
  let!(:event_to_notify) { "created" }
  let!(:rdv) { create(:rdv, id: rdv_id) }
  let!(:participation1) { create(:participation, user: user1, rdv: rdv) }
  let!(:participation2) { create(:participation, user: user2, rdv: rdv) }
  let!(:user1) { create(:user, email: "someone@gmail.com", phone_number: "0607070707") }
  let!(:user2) { create(:user, email: "anotherone@gmail.com", phone_number: "0606070707") }
  let!(:participation_ids) { [participation1.id, participation2.id] }

  describe "#perform" do
    it "enqueues notification jobs for each users and each format" do
      expect(NotifyParticipationToUserJob).to receive(:perform_async)
        .with(participation1.id, "sms", "participation_created")
      expect(NotifyParticipationToUserJob).to receive(:perform_async)
        .with(participation1.id, "email", "participation_created")
      expect(NotifyParticipationToUserJob).to receive(:perform_async)
        .with(participation2.id, "sms", "participation_created")
      expect(NotifyParticipationToUserJob).to receive(:perform_async)
        .with(participation2.id, "email", "participation_created")
      subject
    end

    context "when phone number is not mobile" do
      before { user1.update!(phone_number: "0101010101") }

      it "does not enqueue a notification by sms job" do
        expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
          .with(participation1.id, "sms", "participation_created")
        subject
      end
    end

    context "when the phone number is blank" do
      before { user1.update!(phone_number: nil) }

      it "does not enqueue a notification by sms job" do
        expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
          .with(participation1.id, "sms", "participation_created")
        subject
      end
    end

    context "when there is no email" do
      before { user1.update!(email: nil) }

      it "does not enqueue a notification by email job" do
        expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
          .with(participation1.id, "email", "participation_created")
        subject
      end
    end

    context "when reminder" do
      let!(:event_to_notify) { "reminder" }

      it "enqueues notification jobs for each users and each format" do
        expect(NotifyParticipationToUserJob).to receive(:perform_async)
          .with(participation1.id, "sms", "participation_reminder")
        expect(NotifyParticipationToUserJob).to receive(:perform_async)
          .with(participation1.id, "email", "participation_reminder")
        expect(NotifyParticipationToUserJob).to receive(:perform_async)
          .with(participation2.id, "sms", "participation_reminder")
        expect(NotifyParticipationToUserJob).to receive(:perform_async)
          .with(participation2.id, "email", "participation_reminder")
        subject
      end

      context "when phone number is not mobile" do
        before { user1.update!(phone_number: "0101010101") }

        it "does not enqueue a notification by sms job" do
          expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
            .with(participation1.id, "sms", "participation_reminder")
          subject
        end
      end

      context "when the phone number is blank" do
        before { user1.update!(phone_number: nil) }

        it "does not enqueue a notification by sms job" do
          expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
            .with(participation1.id, "sms", "participation_reminder")
          subject
        end
      end

      context "when there is no email" do
        before { user1.update!(email: nil) }

        it "does not enqueue a notification by email job" do
          expect(NotifyParticipationToUserJob).not_to receive(:perform_async)
            .with(participation1.id, "email", "participation_reminder")
          subject
        end
      end
    end
  end
end
