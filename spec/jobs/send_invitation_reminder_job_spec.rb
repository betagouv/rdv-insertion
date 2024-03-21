describe SendInvitationReminderJob do
  subject do
    described_class.new.perform(follow_up_id, invitation_format)
  end

  let!(:follow_up_id) { 3333 }
  let!(:invitation_format) { "sms" }
  let!(:follow_up) do
    create(
      :follow_up,
      id: follow_up_id,
      user: user,
      status: "invitation_pending",
      motif_category: create(:motif_category, name: "RSA accompagnement")
    )
  end
  let!(:user) do
    create(:user, id: 444)
  end
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:first_invitation) do
    create(
      :invitation,
      valid_until: Time.zone.parse("2022-05-15 15:05"), created_at: Time.zone.parse("2022-05-01 14:01"),
      user: user, organisations: [organisation], follow_up: follow_up, rdv_solidarites_token: "123",
      link: "www.rdv-solidarités.fr/prendre_rdv",
      help_phone_number: "0101010101",
      rdv_solidarites_lieu_id: nil, department: department, rdv_with_referents: false
    )
  end
  let!(:invitation) { build(:invitation) }

  before do
    travel_to(Time.zone.parse("2022-05-04 11:00"))
    allow(Invitation).to receive(:new).and_return(invitation)
    allow(Invitations::SaveAndSend).to receive(:call)
      .with(invitation:, check_creneaux_availability: false)
      .and_return(OpenStruct.new(success?: true))
    allow(MattermostClient).to receive(:send_to_notif_channel)
  end

  it "instanciates an invitation with attributes from the first one" do
    expect(Invitation).to receive(:new)
      .with(
        reminder: true,
        user: user,
        department: department,
        organisations: [organisation],
        follow_up: follow_up,
        format: invitation_format,
        help_phone_number: "0101010101",
        rdv_solidarites_lieu_id: nil,
        link: "www.rdv-solidarités.fr/prendre_rdv",
        rdv_solidarites_token: "123",
        valid_until: Time.zone.parse("2022-05-15 15:05"),
        rdv_with_referents: false
      )
    subject
  end

  it "saves and send the invitation" do
    expect(Invitations::SaveAndSend).to receive(:call)
    subject
  end

  context "when the first invitation was not sent 3 days ago" do
    before { first_invitation.update! created_at: Time.zone.parse("2022-05-02 14:01") }

    it "does not instanciate an invitation" do
      expect(Invitation).not_to receive(:new)
      subject
    end

    it "does not save and send the invitation" do
      expect(Invitations::SaveAndSend).not_to receive(:call)
      subject
    end

    it "sends a notification to mattermost" do
      expect(MattermostClient).to receive(:send_to_notif_channel)
        .with("🚫 L'usager 444 n'est pas éligible à la relance pour RSA accompagnement.")
      subject
    end
  end

  context "when the first invitation expires in less than 2 days" do
    before { first_invitation.update! valid_until: Time.zone.parse("2022-05-05 14:01") }

    it "does not instanciate an invitation" do
      expect(Invitation).not_to receive(:new)
      subject
    end

    it "does not save and send the invitation" do
      expect(Invitations::SaveAndSend).not_to receive(:call)
      subject
    end

    it "sends a notification to mattermost" do
      expect(MattermostClient).to receive(:send_to_notif_channel)
        .with("🚫 L'usager 444 n'est pas éligible à la relance pour RSA accompagnement.")
      subject
    end
  end

  context "when the follow-up status is not invitation_pending" do
    before { follow_up.update! status: "rdv_pending" }

    it "does not instanciate an invitation" do
      expect(Invitation).not_to receive(:new)
      subject
    end

    it "does not save and send the invitation" do
      expect(Invitations::SaveAndSend).not_to receive(:call)
      subject
    end

    it "sends a notification to mattermost" do
      expect(MattermostClient).to receive(:send_to_notif_channel)
        .with("🚫 L'usager 444 n'est pas éligible à la relance pour RSA accompagnement.")
      subject
    end
  end

  context "when an invitation has already been sent in the last 24hrs in the same format" do
    let!(:invitation) { create(:invitation, created_at: Time.zone.parse("2022-05-04 08:00"), follow_up: follow_up) }

    it "does not instanciate an invitation" do
      expect(Invitation).not_to receive(:new)
      subject
    end

    it "does not save and send the invitation" do
      expect(Invitations::SaveAndSend).not_to receive(:call)
      subject
    end
  end

  context "when the save and send service fails" do
    before do
      allow(Invitations::SaveAndSend).to receive(:call)
        .and_return(OpenStruct.new(success?: false, errors: ["cannot send invitation"]))
    end

    it "raises an error" do
      expect { subject }.to raise_error(SendInvitationReminderJobError, "cannot send invitation")
    end
  end
end
