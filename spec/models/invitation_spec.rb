describe Invitation do
  describe "#valid?" do
    let!(:department) { create(:department) }
    let!(:organisation) { create(:organisation, department: department) }
    let!(:user) { create(:user) }
    let!(:follow_up) { build(:follow_up) }
    let!(:invitation) do
      build(
        :invitation,
        organisations: [organisation], department: department, follow_up: follow_up,
        help_phone_number: "0101010101", user: user, rdv_solidarites_token: "rdv_solidarites_token",
        link: "https://www.rdv-solidarites.fr"
      )
    end

    it { expect(invitation).to be_valid }

    context "when no rdv_solidarites_token" do
      before { invitation.rdv_solidarites_token = nil }

      it { expect(invitation).not_to be_valid }
    end

    context "when no link" do
      before { invitation.link = nil }

      it { expect(invitation).not_to be_valid }
    end

    context "when no help_phone_number" do
      before { invitation.help_phone_number = nil }

      it { expect(invitation).not_to be_valid }
    end

    context "when no organisations" do
      before { invitation.organisations = [] }

      it { expect(invitation).not_to be_valid }
    end
  end
end
