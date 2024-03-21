describe Users::Save, type: :service do
  subject do
    described_class.call(organisation:, user:)
  end

  let!(:rdv_solidarites_organisation_id) { 1010 }
  let!(:organisation) do
    create(:organisation, rdv_solidarites_organisation_id: rdv_solidarites_organisation_id)
  end
  let!(:motif_category) { create(:motif_category) }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, motif_category: motif_category)
  end
  let!(:user) { create(:user, organisations: [organisation], rdv_solidarites_user_id: nil) }

  describe "#call" do
    before do
      allow(user).to receive(:save).and_return(true)
      allow(Users::Validate).to receive(:call)
        .with(user: user).and_return(OpenStruct.new(success?: true))
      allow(Users::SyncWithRdvSolidarites).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    it "tries to save the user in db" do
      expect(user).to receive(:save)
      subject
    end

    context "when an organisation is present" do
      it "assigns the user to the organisation" do
        expect(user.reload.organisations).to include(organisation)
        subject
      end
    end

    it "syncs the user with Rdv Solidarites" do
      expect(Users::SyncWithRdvSolidarites).to receive(:call)
        .with(user: user)
      subject
    end

    it "is a success" do
      is_a_success
    end

    context "when organisation is nil" do
      subject { described_class.call(user: user) }

      it "is a success" do
        is_a_success
      end
    end

    context "when the user cannot be saved in db" do
      before do
        allow(user).to receive(:save)
          .and_return(false)
        allow(user).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("some error")
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["some error"])
      end
    end

    context "when the rdv solidarites user sync fails" do
      before do
        allow(Users::SyncWithRdvSolidarites).to receive(:call)
          .and_return(OpenStruct.new(errors: ["some error"], success?: false))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["some error"])
      end
    end

    context "when the user update fails" do
      before do
        allow(user).to receive(:save).and_return(false)
        allow(user).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("update error")
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["update error"])
      end
    end

    context "when the validation service fails" do
      before do
        allow(Users::Validate).to receive(:call)
          .with(user: user).and_return(OpenStruct.new(success?: false, errors: ["invalid user"]))
      end

      it "is a failure" do
        is_a_failure
      end

      it "stores the error" do
        expect(subject.errors).to eq(["invalid user"])
      end
    end
  end
end
