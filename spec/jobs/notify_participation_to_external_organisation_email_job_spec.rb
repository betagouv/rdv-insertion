describe NotifyParticipationToExternalOrganisationEmailJob do
  subject do
    described_class.new.perform(participation_id, event)
  end

  let(:organisation) { create(:organisation) }
  let(:category_configuration) do
    create(:category_configuration, organisation:, notify_rdv_changes: true, notify_rdv_changes_email: "test@test.com")
  end
  let(:follow_up) { create(:follow_up, motif_category_id: category_configuration.motif_category_id) }
  let(:participation) { create(:participation, organisation:, follow_up:) }
  let(:participation_id) { participation.id }

  let(:event) { "created" }

  describe "#perform" do
    context "category_configuration does not notify_rdv_changes" do
      let(:category_configuration) { create(:category_configuration, organisation:, notify_rdv_changes: false) }

      it "does not send the notification" do
        expect(OrganisationMailer).not_to receive(:notify_rdv_changes)
        subject
      end
    end

    context "already notified" do
      before do
        allow_any_instance_of(described_class).to receive(:already_notified?).and_return(true)
      end

      it "does not send the notification" do
        expect(OrganisationMailer).not_to receive(:notify_rdv_changes)
        subject
      end
    end

    context "not notified" do
      before do
        allow_any_instance_of(described_class).to receive(:already_notified?).and_return(false)
      end

      it "sends the notification" do
        expect(OrganisationMailer).to receive(:notify_rdv_changes)
          .once
          .with(
            to: category_configuration.notify_rdv_changes_email,
            organisation: participation.organisation,
            participation: participation,
            event: event
          ).and_return(OpenStruct.new(deliver_now: false))
        subject
      end
    end
  end
end
