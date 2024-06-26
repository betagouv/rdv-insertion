describe User do
  describe "rdv_solidarites_user_id uniqueness validation" do
    context "no collision" do
      let(:user) { build(:user, rdv_solidarites_user_id: 1) }

      it { expect(user).to be_valid }
    end

    context "blank rdv_solidarites_user_id" do
      let!(:user_existing) { create(:user, rdv_solidarites_user_id: 1) }

      let(:user) { build(:user, rdv_solidarites_user_id: "") }

      it { expect(user).to be_valid }
    end

    context "colliding rdv_solidarites_user_id" do
      let!(:user_existing) { create(:user, rdv_solidarites_user_id: 1) }
      let(:user) { build(:user, rdv_solidarites_user_id: 1) }

      it "adds errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ rdv_solidarites_user_id: [{ error: :taken, value: 1 }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("ID de l'usager RDV-Solidarités est déjà utilisé")
      end
    end
  end

  describe "#search_by_text" do
    subject { described_class.search_by_text(query) }

    let!(:user_jean) do
      create(
        :user,
        first_name: "jean",
        last_name: "dujardin",
        email: "jean@dujardin.fr",
        phone_number: "+33110101010",
        affiliation_number: "1111"
      )
    end
    let!(:user_cecile) do
      create(
        :user,
        first_name: "cecile",
        last_name: "defrance",
        email: "cecile@defrance.fr",
        phone_number: nil,
        affiliation_number: "1111"
      )
    end
    let!(:user_romain) do
      create(
        :user,
        first_name: "romain",
        last_name: "duris",
        email: "romain@duris.fr",
        phone_number: "+33782605941",
        affiliation_number: "0000"
      )
    end

    context "name query" do
      let(:query) { "cecile" }

      it { is_expected.to include(user_cecile) }
      it { is_expected.not_to include(user_jean) }
      it { is_expected.not_to include(user_romain) }
    end

    context "email query" do
      let(:query) { "romain@duris" }

      it { is_expected.to include(user_romain) }
      it { is_expected.not_to include(user_cecile) }
      it { is_expected.not_to include(user_jean) }
    end

    context "phone number query" do
      let(:query) { "+3378" }

      it { is_expected.to include(user_romain) }
      it { is_expected.not_to include(user_cecile) }
      it { is_expected.not_to include(user_jean) }
    end

    context "affiliation number query" do
      let(:query) { "1111" }

      it { is_expected.to include(user_jean) }
      it { is_expected.to include(user_cecile) }
      it { is_expected.not_to include(user_romain) }
    end
  end

  describe "email format validation" do
    context "valid email format" do
      let(:user) { build(:user, email: "abc@test.fr") }

      it { expect(user).to be_valid }
    end

    context "nil email" do
      let(:user) { build(:user, email: nil) }

      it { expect(user).to be_valid }
    end

    context "wrong email format" do
      let(:user) { build(:user, email: "abc") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ email: [{ error: :invalid, value: "abc" }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Email n'est pas valide")
      end
    end

    context "almost perfect but incorrect email format" do
      let(:user) { build(:user, email: "abc@abc..fr") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ email: [{ error: :invalid, value: "abc@abc..fr" }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Email n'est pas valide")
      end
    end
  end

  describe "phone format validation" do
    context "valid phone format" do
      let(:user) { build(:user, phone_number: "0123456789") }

      it { expect(user).to be_valid }
    end

    context "nil phone" do
      let(:user) { build(:user, phone_number: nil) }

      it { expect(user).to be_valid }
    end

    context "wrong phone format" do
      let(:user) { build(:user, phone_number: "01234") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ phone_number: [{ error: :invalid }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Téléphone n'est pas valide")
      end
    end
  end

  describe "affiliation number format validation" do
    context "valid affiliation number" do
      let(:user) { create(:user, affiliation_number: "1234567") }

      it { expect(user.affiliation_number).to eq("1234567") }
    end

    context "nil affiliation number" do
      let(:user) { create(:user, affiliation_number: nil) }

      it { expect(user.affiliation_number).to be_nil }
    end

    context "valid affiliation number with more than 7 characters" do
      let(:user) { create(:user, affiliation_number: "12345670008") }

      it { expect(user.affiliation_number).to eq("12345670008") }
    end

    context "valid affiliation number with leading and trailing zeros" do
      let(:user) { create(:user, affiliation_number: "00012345670000") }

      it { expect(user.affiliation_number).to eq("1234567") }
    end
  end

  describe "nir validity" do
    context "when no nir" do
      let(:user) { build(:user, nir: nil) }

      it { expect(user).to be_valid }
    end

    context "when nir is 13 characters" do
      let!(:nir) { generate_random_nir }
      let(:user) { build(:user, nir: nir.first(13)) }

      it { expect(user).to be_valid }

      it "adds a 2 digits key to the nir saved in db" do
        user.save
        expect(user.reload.nir).to eq(nir)
      end
    end

    context "when nir is a valid 15 characters string" do
      let!(:nir) { generate_random_nir }
      let(:user) { build(:user, nir: nir) }

      it { expect(user).to be_valid }
    end

    context "when nir is 13 characters with 2A or 2B in it" do
      let!(:nir) { "123456782A12307" }
      let(:user) { build(:user, nir: nir.first(13)) }

      it { expect(user).to be_valid }

      it "adds a 2 digits key to the nir saved in db" do
        user.save
        expect(user.reload.nir).to eq(nir)
      end
    end

    context "when nir is a valid 15 characters string with 2A or 2B in it" do
      let!(:nir) { "123456782A12307" }
      let(:user) { build(:user, nir: nir) }

      it { expect(user).to be_valid }
    end

    context "when nir exists already" do
      let!(:existing_user) { create(:user, nir: "123456789012311") }
      let(:user) { build(:user, nir: "123456789012311") }

      it { expect(user).not_to be_valid }
    end

    context "when nir is not 13 or 15 characters" do
      let(:user) { build(:user, nir: "12345678901") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ nir: [{ error: :invalid }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Le NIR doit être une série de 13 ou 15 chiffres")
      end
    end

    context "when nir is not all digits" do
      let(:user) { build(:user, nir: "123456C78901211") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ nir: [{ error: :invalid }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Le NIR doit être une série de 13 ou 15 chiffres")
      end
    end

    context "when nir is 15 characters and luhn formula is not matched" do
      let(:user) { build(:user, nir: "123456789012312") }

      it "add errors" do
        expect(user).not_to be_valid
        expect(user.errors.details).to eq({ nir: [{ error: :invalid }] })
        expect(user.errors.full_messages.to_sentence)
          .to include("Le NIR n'est pas valide")
      end
    end
  end

  describe "#notifiable?" do
    subject { user.notifiable? }

    let!(:user) { create(:user, title: "monsieur") }

    it "is notifiable if the title is present" do
      expect(subject).to eq(true)
    end

    context "when the user has no title" do
      let!(:user) { create(:user, title: nil) }

      it "is not notifiable" do
        expect(subject).to eq(false)
      end
    end
  end

  describe "#referents_to_add=" do
    subject { user.save }

    let!(:user) { build(:user) }

    let!(:agent) { create(:agent, email: "someagent@gmail.com") }
    let!(:other_agent) { create(:agent, email: "otheragent@gmail.com") }

    it "assigns the referents" do
      user.referents_to_add = [{ email: "someagent@gmail.com" }, { email: "otheragent@gmail.com" }]
      expect { subject }.to change(ReferentAssignation, :count).by(2)
      expect(user.reload.referent_ids).to contain_exactly(agent.id, other_agent.id)
    end

    context "when the email does not match an existing agent" do
      it "does not assign the referent" do
        user.referents_to_add = [{ email: "donotexist@gmail.com" }]
        expect { subject }.not_to change(ReferentAssignation, :count)
        expect(user.reload.referents).to eq([])
      end
    end

    context "when the agent is already assigned" do
      let!(:user) { create(:user, referents: [agent]) }

      it "does not reassign the assigned referent" do
        user.referents_to_add = [{ email: "someagent@gmail.com" }, { email: "otheragent@gmail.com" }]
        expect { subject }.to change(ReferentAssignation, :count).by(1)
        expect(user.reload.referent_ids).to contain_exactly(agent.id, other_agent.id)
      end
    end
  end
end
