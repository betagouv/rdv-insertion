describe Agent do
  describe "agent email uniqueness validation" do
    context "no collision" do
      let(:agent) { build(:agent, email: "johndoe@example.com") }

      it { expect(agent).to be_valid }
    end

    context "colliding emails" do
      let!(:agent_existing) { create(:agent, email: "johndoe@example.com") }
      let(:agent) { build(:agent, email: "johndoe@example.com") }

      it "adds errors" do
        expect(agent).not_to be_valid
        expect(agent.errors.details).to eq({ email: [{ error: :taken, value: "johndoe@example.com" }] })
        expect(agent.errors.full_messages.to_sentence)
          .to include("Email est déjà utilisé")
      end
    end
  end

  describe "agent inclusion_connect_open_id_sub uniqueness validation" do
    context "no collision" do
      let(:agent) { build(:agent, inclusion_connect_open_id_sub: "test1234") }

      it { expect(agent).to be_valid }
    end

    context "allow nil value" do
      let!(:agent_existing) { create(:agent, inclusion_connect_open_id_sub: nil) }
      let(:agent) { build(:agent, inclusion_connect_open_id_sub: nil) }

      it { expect(agent).to be_valid }
    end

    context "colliding inclusion_connect_open_id_sub" do
      let!(:agent_existing) { create(:agent, inclusion_connect_open_id_sub: "test1234") }
      let(:agent) { build(:agent, inclusion_connect_open_id_sub: "test1234") }

      it "adds errors" do
        expect(agent).not_to be_valid
        expect(agent.errors.details).to eq({ inclusion_connect_open_id_sub: [{ error: :taken,
                                                                               value: "test1234" }] })
        expect(agent.errors.full_messages.to_sentence)
          .to include("Inclusion connect open id sub est déjà utilisé")
      end
    end
  end

  describe "agent email presence validation" do
    context "with no email" do
      let(:agent) { build(:agent, email: "") }

      it "is not valid" do
        expect(agent).not_to be_valid
        expect(agent.errors.details).to eq({ email: [{ error: :blank }] })
      end
    end
  end

  describe "cannot save as super admin" do
    let!(:agent) { create(:agent, super_admin: false) }

    it "cannot update" do
      expect(agent.update(super_admin: true)).to eq(false)
      expect(agent.errors.full_messages.to_sentence).to include("Super admin ne peut pas être mis à jour")
    end

    context "on creation" do
      let!(:agent) { build(:agent) }

      it "is not valid" do
        agent.super_admin = true
        expect(agent).not_to be_valid
        expect(agent.errors.full_messages.to_sentence).to include("Super admin ne peut pas être mis à jour")
      end
    end
  end

  describe "admins are always authorized to export" do
    let!(:organisation) { create(:organisation) }
    let!(:agent) { create(:agent, admin_role_in_organisations: [organisation]) }

    it { expect(agent.export_organisations_ids).to include(organisation.id) }
  end
end
