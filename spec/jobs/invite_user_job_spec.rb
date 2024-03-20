describe InviteUserJob do
  subject do
    described_class.new.perform(
      user_id, organisation_id, invitation_attributes, motif_category_attributes
    )
  end

  let!(:user_id) { 9999 }
  let!(:organisation_id) { 999 }
  let!(:department) { create(:department) }
  let!(:user) { create(:user, id: user_id) }
  let!(:organisation) do
    create(:organisation, id: organisation_id, department: department)
  end
  let!(:invitation_format) { "sms" }
  let!(:invitation_attributes) do
    {
      format: "sms",
      help_phone_number: "01010101",
      rdv_solidarites_lieu_id: 444
    }
  end
  let!(:motif_category_attributes) { { short_name: "rsa_accompagnement" } }

  describe "#perform" do
    before do
      allow(InviteUser).to receive(:call)
        .with(
          user:, organisations: [organisation], invitation_attributes:, motif_category_attributes:,
          check_creneaux_availability: false
        )
        .and_return(OpenStruct.new(success?: true))
    end

    it "invites the user" do
      expect(InviteUser).to receive(:call)
        .with(
          user:, organisations: [organisation], invitation_attributes:, motif_category_attributes:,
          check_creneaux_availability: false
        )
      subject
    end

    context "when it fails to send it" do
      before do
        allow(InviteUser).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["Could not send invite"]))
      end

      it "raises an error" do
        expect { subject }.to raise_error(
          ApplicationJob::FailedServiceError,
          "Calling service InviteUser failed in InviteUserJob:\nErrors: [\"Could not send invite\"]"
        )
      end
    end
  end
end
