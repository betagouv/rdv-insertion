describe Invitations::SendEmail, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  describe "#call" do
    before do
      allow(Messengers::SendEmail).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    context "for rsa orientation" do
      let!(:applicant) { create(:applicant) }
      let!(:invitation) do
        create(
          :invitation,
          applicant: applicant,
          rdv_context: build(:rdv_context, motif_category: "rsa_orientation")
        )
      end

      it("is a success") { is_a_success }

      it "calls the emailer service" do
        expect(Messengers::SendEmail).to receive(:call)
          .with(
            sendable: invitation,
            mailer_class: InvitationMailer,
            mailer_method: :invitation_for_rsa_orientation,
            invitation: invitation,
            applicant: applicant
          )
        subject
      end

      context "when the invitation is a reminder" do
        let!(:invitation) do
          create(
            :invitation,
            applicant: applicant,
            rdv_context: build(:rdv_context, motif_category: "rsa_orientation"),
            reminder: true
          )
        end

        it("is a success") { is_a_success }

        it "calls the emailer service with the reminder mailer method" do
          expect(Messengers::SendEmail).to receive(:call)
            .with(
              sendable: invitation,
              mailer_class: InvitationMailer,
              mailer_method: :invitation_for_rsa_orientation_reminder,
              invitation: invitation,
              applicant: applicant
            )
          subject
        end
      end
    end
  end
end
