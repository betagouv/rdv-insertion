describe Archive do
  subject { build(:archive, organisation: organisation, user: user) }

  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department:) }
  let!(:user) { create(:user) }

  describe "no collision" do
    context "when the user is not archived" do
      let(:archive) { build(:archive, organisation: organisation, user: user) }

      it { expect(subject).to be_valid }
    end

    context "when the user is archived in another organisation" do
      let!(:existing_archive) do
        create(:archive, user: user, organisation: create(:organisation))
      end

      it { expect(subject).to be_valid }
    end

    context "when the user is already archived in the organisation" do
      let!(:existing_archive) do
        create(:archive, user: user, organisation: organisation)
      end

      it { expect(subject).not_to be_valid }
    end
  end

  describe "invitation invalidations" do
    let!(:other_organisation) { create(:organisation, department:) }
    let!(:other_archived_organisation) { create(:organisation, department:) }
    let!(:archive) { create(:archive, user:, organisation: other_archived_organisation) }
    let!(:invitation_for_organisation) do
      create(:invitation, user:, department:, organisations: [organisation])
    end

    let!(:invitation_for_other_organisation) do
      create(:invitation, user:, department:, organisations: [other_organisation])
    end

    let!(:invitation_for_two_organisations) do
      create(:invitation, user:, department:, organisations: [organisation, other_organisation])
    end

    let!(:invitation_for_two_archived_organisations) do
      create(:invitation, user:, department:, organisations: [organisation, other_archived_organisation])
    end

    it "invalidates the user organisation invitations" do
      expect(InvalidateInvitationJob).to receive(:perform_async)
        .with(invitation_for_organisation.id)
      expect(InvalidateInvitationJob).not_to receive(:perform_async)
        .with(invitation_for_other_organisation.id)
      expect(InvalidateInvitationJob).not_to receive(:perform_async)
        .with(invitation_for_two_organisations.id)
      expect(InvalidateInvitationJob).to receive(:perform_async)
        .with(invitation_for_two_archived_organisations.id)

      subject.save
    end
  end
end
