describe Invitations::SendEmail, type: :service do
  subject do
    described_class.call(
      invitation: invitation
    )
  end

  include_context "with all existing categories"

  let!(:user) { create(:user, email: "someemail@someservice.com") }
  let!(:mailer) { instance_double("mailer") }

  describe "#call" do
    before do
      allow(InvitationMailer).to receive(:with)
        .with(invitation: invitation, user: user)
        .and_return(mailer)
    end

    context "for rsa orientation" do
      let!(:invitation) do
        create(
          :invitation,
          format: "email",
          user: user,
          follow_up: build(:follow_up, motif_category: category_rsa_orientation)
        )
      end

      before { allow(mailer).to receive_message_chain(:standard_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:standard_invitation, :deliver_now)
        subject
      end

      context "when the invitation is a reminder" do
        let!(:invitation) do
          create(
            :invitation,
            format: "email",
            user: user,
            follow_up: build(:follow_up, motif_category: category_rsa_orientation),
            reminder: true
          )
        end

        before { allow(mailer).to receive_message_chain(:standard_invitation_reminder, :deliver_now) }

        it("is a success") { is_a_success }

        it "sends the email" do
          expect(mailer).to receive_message_chain(:standard_invitation_reminder, :deliver_now)
          subject
        end
      end

      context "when the invitation format is not email" do
        before { invitation.format = "sms" }

        it("is a failure") { is_a_failure }

        it "returns an error" do
          expect(subject.errors).to eq(["Envoi d'un email alors que le format est sms"])
        end
      end

      context "when the email is blank" do
        before { user.email = nil }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["L'email doit être renseigné"])
        end
      end

      context "when the email format is not valid" do
        before { user.email = "someinvalidmail" }

        it("is a failure") { is_a_failure }

        it "returns the error" do
          expect(subject.errors).to eq(["L'email renseigné ne semble pas être une adresse valable"])
        end
      end
    end

    context "for psychologue" do
      let!(:invitation) do
        create(
          :invitation,
          format: "email",
          user: user,
          follow_up: build(:follow_up, motif_category: category_psychologue)
        )
      end

      before { allow(mailer).to receive_message_chain(:short_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:short_invitation, :deliver_now)
        subject
      end

      context "when the invitation is a reminder" do
        let!(:invitation) do
          create(
            :invitation,
            user: user, format: "email",
            follow_up: build(:follow_up, motif_category: category_psychologue),
            reminder: true
          )
        end

        before { allow(mailer).to receive_message_chain(:short_invitation_reminder, :deliver_now) }

        it("is a success") { is_a_success }

        it "sends the email" do
          expect(mailer).to receive_message_chain(:short_invitation_reminder, :deliver_now)
          subject
        end
      end
    end

    context "for atelier_enfants_ados" do
      let!(:invitation) do
        create(
          :invitation,
          format: "email",
          user: user,
          follow_up: build(:follow_up, motif_category: category_atelier_enfants_ados)
        )
      end

      before { allow(mailer).to receive_message_chain(:atelier_enfants_ados_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:atelier_enfants_ados_invitation, :deliver_now)
        subject
      end

      context "when the invitation is a reminder" do
        let!(:invitation) do
          create(
            :invitation,
            user: user, format: "email",
            follow_up: build(:follow_up, motif_category: category_atelier_enfants_ados),
            reminder: true
          )
        end

        before { allow(mailer).to receive_message_chain(:atelier_enfants_ados_invitation_reminder, :deliver_now) }

        it("is a success") { is_a_success }

        it "sends the email" do
          expect(mailer).to receive_message_chain(:atelier_enfants_ados_invitation_reminder, :deliver_now)
          subject
        end
      end
    end

    context "for rsa_orientation_france_travail" do
      let!(:invitation) do
        create(
          :invitation,
          format: "email",
          user: user,
          follow_up: build(:follow_up, motif_category: category_rsa_orientation_france_travail)
        )
      end

      before { allow(mailer).to receive_message_chain(:standard_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:standard_invitation, :deliver_now)
        subject
      end
    end

    context "for rsa_orientation_on_phone_platform" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_rsa_orientation_on_phone_platform)
        )
      end

      before { allow(mailer).to receive_message_chain(:phone_platform_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:phone_platform_invitation, :deliver_now)
        subject
      end

      context "when the invitation is a reminder" do
        let!(:invitation) do
          create(
            :invitation,
            user: user, format: "email",
            follow_up: build(:follow_up, motif_category: category_rsa_orientation_on_phone_platform),
            reminder: true
          )
        end

        before { allow(mailer).to receive_message_chain(:phone_platform_invitation_reminder, :deliver_now) }

        it("is a success") { is_a_success }

        it "sends the email" do
          expect(mailer).to receive_message_chain(:phone_platform_invitation_reminder, :deliver_now)
          subject
        end
      end
    end

    context "for rsa_insertion_offer" do
      let!(:invitation) do
        create(
          :invitation,
          format: "email",
          user: user,
          follow_up: build(:follow_up, motif_category: category_rsa_insertion_offer)
        )
      end

      before { allow(mailer).to receive_message_chain(:atelier_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:atelier_invitation, :deliver_now)
        subject
      end
    end

    context "for rsa_atelier_competences" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_rsa_atelier_competences)
        )
      end

      before { allow(mailer).to receive_message_chain(:atelier_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:atelier_invitation, :deliver_now)
        subject
      end
    end

    context "for rsa_atelier_rencontres_pro" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_rsa_atelier_rencontres_pro)
        )
      end

      before { allow(mailer).to receive_message_chain(:atelier_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:atelier_invitation, :deliver_now)
        subject
      end
    end

    context "for siae_interview" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_siae_interview)
        )
      end

      before { allow(mailer).to receive_message_chain(:standard_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:standard_invitation, :deliver_now)
        subject
      end
    end

    context "for siae_follow_up" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_siae_follow_up)
        )
      end

      before { allow(mailer).to receive_message_chain(:standard_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:standard_invitation, :deliver_now)
        subject
      end
    end

    context "for siae_collective_information" do
      let!(:invitation) do
        create(
          :invitation,
          user: user, format: "email",
          follow_up: build(:follow_up, motif_category: category_siae_collective_information)
        )
      end

      before { allow(mailer).to receive_message_chain(:standard_invitation, :deliver_now) }

      it("is a success") { is_a_success }

      it "sends the email" do
        expect(mailer).to receive_message_chain(:standard_invitation, :deliver_now)
        subject
      end
    end
  end
end
