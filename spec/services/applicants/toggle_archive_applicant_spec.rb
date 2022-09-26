describe Applicants::ToggleArchiveApplicant, type: :service do
  subject do
    described_class.call(
      rdv_solidarites_session: rdv_solidarites_session,
      applicant: applicant, archiving_reason: archiving_reason,
      archived_at: archived_at
    )
  end

  let!(:applicant) { create(:applicant) }
  let(:rdv_solidarites_session) { instance_double(RdvSolidaritesSession) }
  let!(:archiving_reason) { "some reason" }
  let!(:archived_at) { Time.zone.now }

  describe "#call" do
    before do
      allow(applicant).to receive(:assign_attributes)
        .with(archived_at: archived_at, archiving_reason: archiving_reason)
      allow(applicant).to receive(:save)
        .and_return(true)
      allow(InvalidateInvitationJob).to receive(:perform_async)
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    it "tries to update the applicant" do
      expect(applicant).to receive(:assign_attributes)
        .with(archived_at: archived_at, archiving_reason: archiving_reason)
      expect(applicant).to receive(:save)
      subject
    end

    # it "change the archived_at value" do
    #   subject
    #   expect(applicant.reload.archived_at).to eq(archived_at)
    # end

    # it "saves the archiving_reason" do
    #   subject
    #   expect(applicant.reload.archiving_reason).to eq(archiving_reason)
    # end

    context "when the applicant cannot be updated" do
      before do
        allow(applicant).to receive(:save)
          .and_return(false)
        allow(applicant).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return('some error')
      end

      it "is a failure" do
        expect(subject.success?).to eq(false)
      end

      it "stores the error" do
        expect(subject.errors).to eq(['some error'])
      end
    end

    context "when archived_at is nil" do
      let!(:applicant) { create(:applicant, archived_at: 2.days.ago, archiving_reason: "some reason") }
      let!(:archiving_reason) { nil }
      let!(:archived_at) { nil }

      it "is a success" do
        expect(subject.success?).to eq(true)
      end

      it "tries to update the applicant" do
        expect(applicant).to receive(:assign_attributes)
        expect(applicant).to receive(:save)
        subject
      end

      # it "change the archived_at value" do
      #   subject
      #   expect(applicant.reload.archived_at).to eq(archived_at)
      # end

      # it "saves the archiving_reason" do
      #   subject
      #   expect(applicant.reload.archiving_reason).to eq(archiving_reason)
      # end
    end
  end
end
