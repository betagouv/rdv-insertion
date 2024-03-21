describe SendPeriodicInviteJob do
  subject do
    described_class.new.perform
  end

  describe "#perform" do
    subject do
      described_class.new.perform(invitation.id, category_configuration.id, format)
    end

    let!(:format) { "email" }
    let!(:organisation) { create(:organisation) }
    let!(:category_configuration) do
      create(:category_configuration,
             organisation: organisation,
             number_of_days_between_periodic_invites: 15,
             motif_category: motif_category)
    end
    let!(:motif_category) { create(:motif_category, optional_rdv_subscription: false) }
    let!(:rdv_context) { create(:rdv_context, motif_category: motif_category) }
    let!(:invitation) do
      create(
        :invitation,
        rdv_context: rdv_context,
        created_at: 15.days.ago,
        valid_until: 1.day.ago,
        organisations: [organisation]
      )
    end

    describe "#perform" do
      it "duplicates previous invitation" do
        expect { subject }.to change(Invitation, :count).by(1)
        invitation = Invitation.last

        expect(invitation).to have_attributes(
          rdv_context: invitation.rdv_context,
          motif_category: invitation.motif_category,
          user: invitation.user,
          format: "email"
        )

        expect(invitation.valid_until.end_of_day).to eq(
          category_configuration
            .number_of_days_before_action_required
            .days
            .from_now
            .end_of_day
        )
      end

      it "sends invitation" do
        expect(Invitations::SaveAndSend).to receive(:call).once

        subject
      end

      context "when the user has already been invited in this category less than 1 day ago" do
        let!(:other_invitation) { create(:invitation, rdv_context:, format:, created_at: 2.hours.ago) }

        it "does not send an invitation" do
          expect(Invitations::SaveAndSend).not_to receive(:call)
          expect { subject }.not_to change(Invitation, :count)
        end
      end
    end
  end
end
