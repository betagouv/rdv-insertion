describe CreateAndInviteUserJob do
  subject do
    described_class.new.perform(
      organisation_id, user_attributes, invitation_attributes, motif_category_attributes
    )
  end

  let!(:organisation_id) { 99 }
  let!(:department) { create(:department) }
  let!(:organisation) do
    create(
      :organisation,
      department: department, id: organisation_id, phone_number: "0146292929"
    )
  end
  let!(:user) { create(:user, **user_attributes) }
  let!(:user_attributes) do
    { department_internal_id: "1919", affiliation_number: "00001", role: "conjoint", phone_number: "0607070707",
      email: "john.doe@apijob.com" }
  end
  let!(:invitation_attributes) { { rdv_solidarites_lieu_id: 888 } }
  let!(:motif_category_attributes) { { short_name: "rsa_orientation" } }
  let!(:email_invitation_attributes) { invitation_attributes.merge(format: "email") }
  let!(:sms_invitation_attributes) { invitation_attributes.merge(format: "sms") }

  before do
    allow(InviteUserJob).to receive(:perform_async)
    allow(Users::Upsert).to receive(:call)
      .with(organisation:, user_attributes:)
      .and_return(OpenStruct.new(success?: true, user: user))
  end

  it "upserts the user" do
    expect(Users::Upsert).to receive(:call)
      .with(user_attributes:, organisation: organisation)
    subject
  end

  it "enqueues invite user jobs" do
    expect(InviteUserJob).to receive(:perform_async)
      .with(
        user.id, organisation.id, sms_invitation_attributes, motif_category_attributes
      )
    expect(InviteUserJob).to receive(:perform_async)
      .with(
        user.id, organisation.id, email_invitation_attributes, motif_category_attributes
      )
    subject
  end

  context "when there is no phone" do
    before { user.update! phone_number: nil }

    it "does not enqueue an invite sms job" do
      expect(InviteUserJob).not_to receive(:perform_async)
        .with(
          user.id, organisation.id, sms_invitation_attributes, motif_category_attributes
        )
      subject
    end
  end

  context "when the phone is not a mobile" do
    before { user.update! phone_number: "0101010101" }

    it "does not enqueue an invite sms job" do
      expect(InviteUserJob).not_to receive(:perform_async)
        .with(
          user.id, organisation.id, sms_invitation_attributes, motif_category_attributes
        )
      subject
    end
  end

  context "when there is no email" do
    before { user.update! email: nil }

    it "does not enqueue an invite email job" do
      expect(InviteUserJob).not_to receive(:perform_async)
        .with(
          user.id, organisation.id, email_invitation_attributes, motif_category_attributes
        )
      subject
    end
  end

  context "when the save fails" do
    let!(:department_mail) { instance_double("mail") }

    before do
      allow(Users::Upsert).to receive(:call)
        .and_return(OpenStruct.new(success?: false, errors: ["could not save user"]))
      allow(DepartmentMailer).to receive(:create_user_error).and_return(department_mail)
      allow(department_mail).to receive(:deliver_now)
    end

    it "sends an email to the department and raises" do
      expect(DepartmentMailer).to receive(:create_user_error)
        .with(department, user_attributes, ["could not save user"])
      expect(department_mail).to receive(:deliver_now)
      expect { subject }.to raise_error(
        ApplicationJob::FailedServiceError,
        'Error upserting user in CreateAndInviteUserJob: ["could not save user"]'
      )
    end
  end
end
