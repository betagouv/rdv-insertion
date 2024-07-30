describe InviteUser, type: :service do
  subject do
    described_class.call(
      user:, organisations:, invitation_attributes:, motif_category_attributes:, check_creneaux_availability:
    )
  end

  let!(:check_creneaux_availability) { true }
  let!(:department) { create(:department) }
  let!(:user) { create(:user, organisations: [organisation]) }
  let!(:organisation) { create(:organisation, department:, category_configurations: [category_configuration]) }
  let!(:organisations) { [organisation] }
  let!(:category_configuration) do
    create(
      :category_configuration,
      motif_category:, rdv_with_referents: true, invite_to_user_organisations_only: true,
      number_of_days_before_action_required: 5
    )
  end

  let!(:invitation_attributes) { { format: "sms", rdv_solidarites_lieu_id: 2 } }
  let!(:motif_category) { create(:motif_category, **motif_category_attributes) }
  let!(:motif_category_attributes) { { short_name: "rsa_accompagnement" } }
  let!(:follow_up) { create(:follow_up, user:, motif_category:) }

  let!(:invitation) { build(:invitation) }
  let!(:now) { Time.zone.parse("24/12/2022") }

  describe "#call" do
    before do
      travel_to now
      allow(Invitation).to receive(:new).and_return(invitation)
      allow(Invitations::SaveAndSend).to receive(:call)
        .and_return(OpenStruct.new(success?: true))
    end

    it "is a success" do
      is_a_success
    end

    it "instanciates an invitation" do
      expect(Invitation).to receive(:new)
        .with(
          organisations: [organisation], user:, department:, follow_up:, valid_until: 5.days.from_now,
          rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
          help_phone_number: organisation.phone_number
        )
      subject
    end

    it "saves and send the invitation" do
      expect(Invitations::SaveAndSend).to receive(:call)
        .with(invitation:, check_creneaux_availability:)
      subject
    end

    context "when there is no motif category attributes" do
      let!(:motif_category_attributes) { {} }

      context "when there is only one available category_configuration" do
        it "is a success" do
          is_a_success
        end

        it "instanciates an invitation" do
          expect(Invitation).to receive(:new)
            .with(
              organisations: [organisation], user:, department:, follow_up:, valid_until: 5.days.from_now,
              rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
              help_phone_number: organisation.phone_number
            )
          subject
        end

        it "saves and send the invitation" do
          expect(Invitations::SaveAndSend).to receive(:call)
            .with(invitation:, check_creneaux_availability:)
          subject
        end
      end

      context "when there are multiple available category_configurations" do
        before { organisation.category_configurations << create(:category_configuration) }

        it "is a failure" do
          is_a_failure
        end

        it "does not instanciate an invitation" do
          expect(Invitation).not_to receive(:new)
          subject
        end

        it "does not call the save and send service" do
          expect(Invitations::SaveAndSend).not_to receive(:call)
          subject
        end

        it "stores the error" do
          expect(subject.errors).to eq(["Plusieurs catégories de motifs disponibles et aucune n'a été choisie"])
        end
      end

      context "when there are multiple organisations" do
        let!(:other_org) { create(:organisation) }
        let!(:organisations) { [organisation, other_org] }

        context "when the invitation is restricted to user organisations" do
          it "is a success" do
            is_a_success
          end

          it "invites to the user org only" do
            expect(Invitation).to receive(:new)
              .with(
                organisations: [organisation], user:, department:, follow_up:, valid_until: 5.days.from_now,
                rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
                help_phone_number: organisation.phone_number
              )
            subject
          end

          it "saves and send the invitation" do
            expect(Invitations::SaveAndSend).to receive(:call)
            subject
          end

          context "when the user is archived in the org" do
            let!(:archive) { create(:archive, organisation:, user:) }

            it "does not take the org in account" do
              expect(Invitation).to receive(:new)
                .with(
                  organisations: [], user:, department:, follow_up:, valid_until: 5.days.from_now,
                  rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
                  help_phone_number: organisation.phone_number
                )
              subject
            end
          end
        end

        context "when the category_configuration has a custom phone number" do
          let(:phone_number) { "0102030405" }

          before { category_configuration.update!(phone_number:) }

          it "invites with the proper phone number" do
            expect(Invitation).to receive(:new)
              .with(
                organisations: [organisation], user:, department:, follow_up:, valid_until: 5.days.from_now,
                rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
                help_phone_number: phone_number
              )
            subject
          end
        end

        context "when the invitation is not restricted to the user organisations" do
          before { category_configuration.update! invite_to_user_organisations_only: false }

          it "is a success" do
            is_a_success
          end

          it "invites to all the orgs" do
            expect(Invitation).to receive(:new)
              .with(
                organisations:, user:, department:, follow_up:, valid_until: 5.days.from_now,
                rdv_with_referents: true, format: "sms", rdv_solidarites_lieu_id: 2,
                help_phone_number: organisation.phone_number
              )
            subject
          end

          it "saves and send the invitation" do
            expect(Invitations::SaveAndSend).to receive(:call)
            subject
          end
        end
      end
    end
  end
end
