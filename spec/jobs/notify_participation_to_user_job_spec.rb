describe NotifyParticipationToUserJob do
  subject do
    described_class.new.perform(participation_id, format, event)
  end

  let!(:participation_id) { 3232 }
  let!(:participation) { create(:participation, id: participation_id, user:) }
  let!(:user) { create(:user) }
  let!(:format) { "sms" }
  let!(:event) { "participation_created" }

  describe "#perform" do
    before do
      allow(Notifications::SaveAndSend).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
      allow(Participation).to receive(:find).and_return(participation)
      allow(participation).to receive_messages(user: user, notifiable?: true)
      allow(user).to receive(:notifiable?).and_return(true)
    end

    it "calls the notify user service" do
      expect(Notifications::SaveAndSend).to receive(:call)
        .with(participation: participation, format: format, event: event)
      subject
    end

    context "when the service fails" do
      before do
        allow(Notifications::SaveAndSend).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["cannot notify"]))
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          ApplicationJob::FailedServiceError,
          "Calling service Notifications::SaveAndSend failed in " \
          "NotifyParticipationToUserJob:\nErrors: [\"cannot notify\"]"
        )
      end
    end

    context "when the user has already been notified for this rdv" do
      let!(:notification) do
        create(:notification, participation: participation, event: event)
      end

      it "does not calls the notify user service" do
        expect(Notifications::SaveAndSend).not_to receive(:call)
        subject
      end

      context "when the event is participation_updated" do
        let!(:event) { "participation_updated" }

        it "still calls the notify user service" do
          expect(Notifications::SaveAndSend).to receive(:call)
            .with(participation: participation, format: format, event: event)
          subject
        end

        context "when there has been two sent notifications in the past hour" do
          let!(:notification) do
            create(:notification, participation: participation, event: event, created_at: 40.minutes.ago)
          end
          let!(:notification2) do
            create(:notification, participation: participation, event: event, created_at: 20.minutes.ago)
          end

          it "does not calls the notify user service" do
            expect(Notifications::SaveAndSend).not_to receive(:call)
            subject
          end
        end
      end

      context "when the user is not notifiable" do
        before { allow(user).to receive(:notifiable?).and_return(false) }

        it "does notify the user" do
          expect(Notifications::SaveAndSend).not_to receive(:call)
          subject
        end
      end

      context "when the participation is not notifiable" do
        before { allow(participation).to receive(:notifiable?).and_return(false) }

        it "does notify the user" do
          expect(Notifications::SaveAndSend).not_to receive(:call)
          subject
        end
      end

      context "when it is a reminder of cancelled participation" do
        let!(:event) { "participation_reminder" }

        before { participation.update! status: "revoked" }

        it "does notify the user" do
          expect(Notifications::SaveAndSend).not_to receive(:call)
          subject
        end
      end
    end
  end
end
