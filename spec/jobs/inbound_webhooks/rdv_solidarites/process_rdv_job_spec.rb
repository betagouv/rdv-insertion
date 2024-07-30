describe InboundWebhooks::RdvSolidarites::ProcessRdvJob do
  subject do
    described_class.new.perform(data, meta)
  end

  let!(:user_id1) { user.rdv_solidarites_user_id }
  let!(:user_id2) { user2.rdv_solidarites_user_id }

  let!(:user_ids) { [user_id1, user_id2] }
  let!(:rdv_solidarites_rdv_id) { 22 }
  let!(:rdv_solidarites_organisation_id) { 52 }
  let!(:rdv_solidarites_lieu_id) { 43 }
  let!(:rdv_solidarites_motif_id) { 53 }
  let!(:participations_attributes) do
    [
      { id: 998, status: "unknown", created_by: "user", user: { id: user_id1 } },
      { id: 999, status: "unknown", created_by: "user", user: { id: user_id2 } }
    ]
  end
  let!(:lieu_attributes) { { id: rdv_solidarites_lieu_id, name: "DINUM", address: "20 avenue de Ségur" } }
  let!(:motif_attributes) do
    {
      id: 53,
      location_type: "public_office",
      motif_category: { short_name: "rsa_orientation" },
      name: "RSA orientation"
    }
  end
  let!(:users) do
    [
      { id: user_id1, first_name: "James", last_name: "Cameron", created_at: "2021-05-29 14:50:22 +0200",
        phone_number: "0755929249", email: nil, birth_date: nil, address: "50 rue Victor Hugo 93500 Pantin",
        organisation_ids: [rdv_solidarites_organisation_id] },
      { id: user_id2, first_name: "Jane", last_name: "Campion", created_at: "2021-05-29 14:20:20 +0200",
        email: "jane@campion.com", phone_number: nil, birth_date: nil, address: nil,
        organisation_ids: [rdv_solidarites_organisation_id] }
    ]
  end
  let!(:starts_at) { "2021-09-08 12:00:00 UTC" }
  let!(:data) do
    {
      "id" => rdv_solidarites_rdv_id,
      "starts_at" => starts_at,
      "address" => "20 avenue de segur",
      "context" => "all good",
      "lieu" => lieu_attributes,
      "motif" => motif_attributes,
      "users" => users,
      "participations" => participations_attributes,
      "organisation" => { id: rdv_solidarites_organisation_id },
      "agents" => [{ id: agent.rdv_solidarites_agent_id }]
    }.deep_symbolize_keys
  end

  let!(:timestamp) { "2021-05-30 14:44:22 +0200" }
  let!(:meta) do
    {
      "model" => "Rdv",
      "event" => "created",
      "timestamp" => timestamp
    }.deep_symbolize_keys
  end

  let!(:user) { create(:user, organisations: [organisation], id: 3) }
  let!(:user2) { create(:user, organisations: [organisation], id: 4) }

  let!(:agent) { create(:agent) }

  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", optional_rdv_subscription: false) }
  let!(:category_configuration) do
    create(:category_configuration, organisation: organisation, convene_user: false, motif_category: motif_category)
  end
  let!(:organisation) do
    create(
      :organisation,
      rdv_solidarites_organisation_id: rdv_solidarites_organisation_id
    )
  end
  let!(:motif) { create(:motif, rdv_solidarites_motif_id: rdv_solidarites_motif_id) }
  let!(:lieu) do
    create(
      :lieu, rdv_solidarites_lieu_id: rdv_solidarites_lieu_id, name: "DINUM", address: "20 avenue de Ségur",
             organisation: organisation
    )
  end

  let!(:invitation) do
    create(
      :invitation,
      organisations: [organisation],
      follow_up: follow_up,
      valid_until: 3.days.from_now
    )
  end

  let!(:invitation2) do
    create(
      :invitation,
      organisations:
      [organisation],
      follow_up: follow_up2,
      valid_until: 3.days.from_now
    )
  end

  let!(:invitation3) do
    create(
      :invitation,
      organisations: [organisation],
      follow_up: follow_up,
      valid_until: 3.days.ago
    )
  end

  let!(:follow_up) do
    build(:follow_up, motif_category: motif_category, user: user)
  end

  let!(:follow_up2) do
    build(:follow_up, motif_category: motif_category, user: user2)
  end

  # rubocop:disable RSpec/ExampleLength
  describe "#perform" do
    before do
      allow(FollowUp).to receive(:find_or_create_by!)
        .with(user: user, motif_category: motif_category)
        .and_return(follow_up)
      allow(FollowUp).to receive(:find_or_create_by!)
        .with(user: user2, motif_category: motif_category)
        .and_return(follow_up2)
      allow(UpsertRecordJob).to receive(:perform_async)
      allow(InvalidateInvitationJob).to receive(:perform_async)
      allow(DeleteRdvJob).to receive(:perform_async)
      allow(MattermostClient).to receive(:send_to_notif_channel)
    end

    context "when no organisation is found" do
      let!(:organisation) { create(:organisation, rdv_solidarites_organisation_id: "random-orga-id") }

      it "raises an error" do
        expect { subject }.to raise_error(WebhookProcessingJobError, "Organisation not found with id 52")
      end
    end

    context "when no motif is found" do
      let!(:motif) { create(:motif, rdv_solidarites_motif_id: "random-motif-id") }

      it "raises an error" do
        expect { subject }.to raise_error(WebhookProcessingJobError, "Motif not found with id 53")
      end
    end

    describe "upserting the rdv" do
      let!(:expected_participation_attributes) do
        [
          {
            id: nil,
            status: "unknown",
            created_by: "user",
            user_id: user.id,
            rdv_solidarites_participation_id: 998,
            follow_up_id: follow_up.id,
            convocable: false,
            rdv_solidarites_agent_prescripteur_id: nil
          },
          {
            id: nil,
            status: "unknown",
            created_by: "user",
            user_id: user2.id,
            rdv_solidarites_participation_id: 999,
            follow_up_id: follow_up2.id,
            convocable: false,
            rdv_solidarites_agent_prescripteur_id: nil
          }
        ]
      end

      context "it upserts the rdv (for a create)" do
        it "enqueues a job to upsert the rdv" do
          expect(UpsertRecordJob).to receive(:perform_async)
            .with(
              "Rdv",
              data,
              {
                participations_attributes: expected_participation_attributes,
                agent_ids: [agent.id],
                organisation_id: organisation.id,
                motif_id: motif.id,
                lieu_id: lieu.id,
                last_webhook_update_received_at: timestamp
              }
            )

          subject
        end

        it "enqueues jobs to invalidate the related sent valid invitations" do
          expect(InvalidateInvitationJob).to receive(:perform_async).exactly(1).time.with(invitation.id)
          expect(InvalidateInvitationJob).to receive(:perform_async).exactly(1).time.with(invitation2.id)
          expect(InvalidateInvitationJob).not_to receive(:perform_async).with(invitation3.id)
          subject
        end

        context "when participation is optional" do
          let!(:motif_category) do
            create(:motif_category, short_name: "rsa_orientation", optional_rdv_subscription: true)
          end

          it "does not enqueue a job to invalidate the related sent valid invitations" do
            expect(InvalidateInvitationJob).not_to receive(:perform_async)
            subject
          end
        end

        it "does not change the user count" do
          expect { subject }.not_to change(User, :count)
        end

        context "when one of the user is not yet created" do
          let!(:user_id1) { 82_821 }

          let!(:new_user) { build(:user, rdv_solidarites_user_id: user_id1) }
          let!(:new_follow_up) do
            build(:follow_up, motif_category: motif_category, user: new_user)
          end

          before do
            allow(User).to receive(:create!).and_return(new_user)
            allow(FollowUp).to receive(:find_or_create_by!)
              .with(user: new_user, motif_category: motif_category)
              .and_return(new_follow_up)
          end

          it "creates the user" do
            expect(User).to receive(:create!).with(
              rdv_solidarites_user_id: user_id1,
              organisations: [organisation],
              first_name: "James",
              last_name: "Cameron",
              address: "50 rue Victor Hugo 93500 Pantin",
              phone_number: "0755929249",
              created_through: "rdv_solidarites_webhook",
              created_from_structure: organisation
            )
            subject
          end

          it "still upserts the rdv with the right attributes" do
            expect(UpsertRecordJob).to receive(:perform_async)
              .with(
                "Rdv",
                data,
                {
                  participations_attributes: [
                    {
                      id: nil,
                      status: "unknown",
                      created_by: "user",
                      user_id: user2.id,
                      rdv_solidarites_participation_id: 999,
                      follow_up_id: follow_up2.id,
                      convocable: false,
                      rdv_solidarites_agent_prescripteur_id: nil
                    },
                    {
                      id: nil,
                      status: "unknown",
                      created_by: "user",
                      user_id: new_user.id,
                      rdv_solidarites_participation_id: 998,
                      follow_up_id: new_follow_up.id,
                      convocable: false,
                      rdv_solidarites_agent_prescripteur_id: nil
                    }
                  ],
                  organisation_id: organisation.id,
                  agent_ids: [agent.id],
                  motif_id: motif.id,
                  lieu_id: lieu.id,
                  last_webhook_update_received_at: timestamp
                }
              )
            subject
          end

          context "when the users belongs to multiple organisations" do
            let!(:other_org) do
              create(:organisation, rdv_solidarites_organisation_id: other_rdv_solidarites_organisation_id)
            end
            let!(:other_rdv_solidarites_organisation_id) { 12_415_332 }

            let!(:users) do
              [
                {
                  id: user_id1, first_name: "James", last_name: "Cameron", created_at: "2021-05-29 14:50:22 +0200",
                  phone_number: "0755929249", email: nil, birth_date: nil, address: "50 rue Victor Hugo 93500 Pantin",
                  organisation_ids: [rdv_solidarites_organisation_id, other_rdv_solidarites_organisation_id]
                }
              ]
            end

            it "creates the users in all the orgs" do
              expect(User).to receive(:create!).with(
                rdv_solidarites_user_id: user_id1,
                organisations: [organisation, other_org],
                first_name: "James",
                last_name: "Cameron",
                address: "50 rue Victor Hugo 93500 Pantin",
                phone_number: "0755929249",
                created_through: "rdv_solidarites_webhook",
                created_from_structure: organisation
              )
              subject
            end
          end
        end

        context "when a user is deleted" do
          let!(:users) do
            [
              { id: 213_123, first_name: "Usager supprimé", last_name: "Usager supprimé",
                phone_number: "0755929249", email: "user@deleted.rdv-solidarites.fr" },
              { id: user_id2, first_name: "Jane", last_name: "Campion", created_at: "2021-05-29 14:20:20 +0200",
                email: "jane@campion.com", phone_number: nil, birth_date: nil, address: nil }
            ]
          end

          before { user.update! rdv_solidarites_user_id: nil }

          it "discards the deleted user participation" do
            expect(UpsertRecordJob).to receive(:perform_async)
              .with(
                "Rdv",
                data,
                {
                  participations_attributes: [{
                    id: nil,
                    status: "unknown",
                    created_by: "user",
                    user_id: user2.id,
                    rdv_solidarites_participation_id: 999,
                    follow_up_id: follow_up2.id,
                    convocable: false,
                    rdv_solidarites_agent_prescripteur_id: nil
                  }],
                  agent_ids: [agent.id],
                  organisation_id: organisation.id,
                  motif_id: motif.id,
                  lieu_id: lieu.id,
                  last_webhook_update_received_at: timestamp
                }
              )
            subject
          end

          it "does not create a user" do
            expect(User).not_to receive(:create!)
            subject
          end
        end
      end

      context "for a participation update and destroy" do
        let!(:participations_attributes) do
          [{ id: 999, status: "seen", created_by: "user", user: { id: user_id2 } }]
        end
        let!(:users) { [{ id: user_id2 }] }

        # Rdv create factory create a new user (and participation) by default
        let!(:rdv) { create(:rdv, rdv_solidarites_rdv_id: rdv_solidarites_rdv_id, organisation: organisation, motif:) }
        let!(:default_user) { rdv.users.first }
        let!(:default_participation) { rdv.participations.first }
        let!(:participation2) do
          create(
            :participation,
            user: user2,
            rdv: rdv,
            status: "unknown",
            id: 2,
            rdv_solidarites_participation_id: 999
          )
        end
        let!(:participations_attributes_expected) do
          [
            {
              id: 2,
              status: "seen",
              created_by: "user",
              user_id: 4,
              rdv_solidarites_participation_id: 999,
              follow_up_id: follow_up2.id,
              rdv_solidarites_agent_prescripteur_id: nil
            },
            {
              _destroy: true,
              user_id: default_user.id,
              id: default_participation.id
            }
          ]
        end

        it "enqueues a job to upsert the rdv with updated status and destroyed participation" do
          expect(UpsertRecordJob).to receive(:perform_async)
            .with(
              "Rdv",
              data,
              {
                participations_attributes: participations_attributes_expected,
                agent_ids: [agent.id],
                organisation_id: organisation.id,
                motif_id: motif.id,
                lieu_id: lieu.id,
                last_webhook_update_received_at: timestamp
              }
            )

          subject
        end
      end
    end

    context "when it is a destroy event" do
      let!(:meta) { { "model" => "Rdv", "event" => "destroyed" }.deep_symbolize_keys }

      it "enqueues a delete job" do
        expect(DeleteRdvJob).to receive(:perform_async)
          .with(rdv_solidarites_rdv_id)
        subject
      end

      context "when the webhook reason is rgpd" do
        let!(:meta) { { "model" => "Rdv", "event" => "destroyed", "webhook_reason" => "rgpd" }.deep_symbolize_keys }
        let!(:rdv) { create(:rdv, rdv_solidarites_rdv_id: rdv_solidarites_rdv_id, organisation: organisation, motif:) }

        it "enqueues a nullify job" do
          expect(NullifyRdvSolidaritesIdJob).to receive(:perform_async)
            .with("Rdv", rdv.id)
          subject
        end

        it "does not enqueue a delete job" do
          expect(DeleteRdvJob).not_to receive(:perform_async)
          subject
        end
      end
    end

    context "with an invalid category" do
      let!(:motif_attributes) { { id: 53, location_type: "public_office", category: nil } }

      it "does not call any job" do
        [UpsertRecordJob, DeleteRdvJob].each do |klass|
          expect(klass).not_to receive(:perform_async)
        end
        subject
      end
    end

    context "with no matching category_configuration" do
      let!(:motif_attributes) { { id: 53, location_type: "public_office", category: "rsa_accompagnement" } }

      it "does not call any job" do
        [UpsertRecordJob, DeleteRdvJob].each do |klass|
          expect(klass).not_to receive(:perform_async)
        end
        subject
      end
    end

    describe "#convocations" do
      context "when the motif mentions 'convocation'" do
        let!(:motif_attributes) do
          {
            id: 53,
            location_type: "public_office",
            motif_category: { short_name: "rsa_orientation" },
            name: "RSA orientation: Convocation"
          }
        end
        let!(:category_configuration) do
          create(:category_configuration, organisation: organisation, convene_user: true,
                                          motif_category: motif_category)
        end

        it "sets the convocable attribute when upserting the rdv" do
          expect(UpsertRecordJob).to receive(:perform_async).with(
            "Rdv",
            data,
            {
              participations_attributes: [
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 3,
                  rdv_solidarites_participation_id: 998,
                  follow_up_id: follow_up.id,
                  convocable: true,
                  rdv_solidarites_agent_prescripteur_id: nil
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  follow_up_id: follow_up2.id,
                  convocable: true,
                  rdv_solidarites_agent_prescripteur_id: nil
                }
              ],
              organisation_id: organisation.id,
              agent_ids: [agent.id],
              motif_id: motif.id,
              lieu_id: lieu.id,
              last_webhook_update_received_at: timestamp
            }
          )
          subject
        end

        context "when the category_configuration does not handle convocations" do
          before { category_configuration.update! convene_user: false }

          it "sets the convocable attribute when upserting the rdv" do
            expect(UpsertRecordJob).to receive(:perform_async) do |_, _, args|
              expected_participation_attributes = [
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 3,
                  rdv_solidarites_participation_id: 998,
                  follow_up_id: follow_up.id,
                  convocable: false,
                  rdv_solidarites_agent_prescripteur_id: nil
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  follow_up_id: follow_up2.id,
                  convocable: false,
                  rdv_solidarites_agent_prescripteur_id: nil
                }
              ]
              # Here we sort the participations by user_id to ensure the test doesn't get flaky and matches
              # the expected attributes above
              result_sorted_by_user_id = args[:participations_attributes].sort_by { |h| h[:user_id] }

              expect(result_sorted_by_user_id).to eq(expected_participation_attributes)

              expect(args[:organisation_id]).to eq(organisation.id)
              expect(args[:agent_ids]).to eq([agent.id])
              expect(args[:motif_id]).to eq(motif.id)
              expect(args[:lieu_id]).to eq(lieu.id)
              expect(args[:last_webhook_update_received_at]).to eq(timestamp)
            end
            subject
          end
        end

        context "when the lieu in the webhook is not sync with the one in db" do
          context "when no lieu attrributes is in the webhook" do
            let!(:lieu_attributes) { nil }

            it "raises an error" do
              expect { subject }.to raise_error(WebhookProcessingJobError, "Lieu in webhook is not coherent. ")
            end
          end

          context "when the attributes in the webhooks do not match the ones in db" do
            let!(:lieu_attributes) { { id: rdv_solidarites_lieu_id, name: "DITP", address: "7 avenue de Ségur" } }

            it "raises an error" do
              expect { subject }.to raise_error(
                WebhookProcessingJobError, "Lieu in webhook is not coherent. #{lieu_attributes}"
              )
            end
          end
        end
      end

      context "when it is a collectif rdv with agent created participations" do
        let!(:motif_attributes) do
          {
            id: 53,
            location_type: "public_office",
            motif_category: { short_name: "rsa_orientation" },
            name: "RSA orientation", collectif: true
          }
        end
        let!(:category_configuration) do
          create(:category_configuration, organisation: organisation, convene_user: true,
                                          motif_category: motif_category)
        end
        let!(:participations_attributes) do
          [
            { id: 998, status: "unknown", created_by: "agent", user: { id: user_id1 } },
            { id: 999, status: "unknown", created_by: "user", user: { id: user_id2 } }
          ]
        end

        it "sets the participations created by the agent as convocable" do
          expect(UpsertRecordJob).to receive(:perform_async).with(
            "Rdv",
            data,
            {
              participations_attributes: [
                {
                  id: nil,
                  status: "unknown",
                  created_by: "agent",
                  user_id: 3,
                  rdv_solidarites_participation_id: 998,
                  follow_up_id: follow_up.id,
                  convocable: true,
                  rdv_solidarites_agent_prescripteur_id: nil
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  follow_up_id: follow_up2.id,
                  convocable: false,
                  rdv_solidarites_agent_prescripteur_id: nil
                }
              ],
              organisation_id: organisation.id,
              agent_ids: [agent.id],
              motif_id: motif.id,
              lieu_id: lieu.id,
              last_webhook_update_received_at: timestamp
            }
          )
          subject
        end

        context "when the category_configuration does not handle convocations" do
          before { category_configuration.update! convene_user: false }

          it "sets the convocable attribute when upserting the rdv" do
            expect(UpsertRecordJob).to receive(:perform_async).with(
              "Rdv",
              data,
              {
                participations_attributes: [
                  {
                    id: nil,
                    status: "unknown",
                    created_by: "agent",
                    user_id: 3,
                    rdv_solidarites_participation_id: 998,
                    follow_up_id: follow_up.id,
                    convocable: false,
                    rdv_solidarites_agent_prescripteur_id: nil
                  },
                  {
                    id: nil,
                    status: "unknown",
                    created_by: "user",
                    user_id: 4,
                    rdv_solidarites_participation_id: 999,
                    follow_up_id: follow_up2.id,
                    convocable: false,
                    rdv_solidarites_agent_prescripteur_id: nil
                  }
                ],
                organisation_id: organisation.id,
                agent_ids: [agent.id],
                motif_id: motif.id,
                lieu_id: lieu.id,
                last_webhook_update_received_at: timestamp
              }
            )
            subject
          end
        end

        context "when the lieu in the webhook is not sync with the one in db" do
          context "when no lieu attrributes is in the webhook" do
            let!(:lieu_attributes) { nil }

            it "raises an error" do
              expect { subject }.to raise_error(WebhookProcessingJobError, "Lieu in webhook is not coherent. ")
            end
          end

          context "when the attributes in the webhooks do not match the ones in db" do
            let!(:lieu_attributes) { { id: rdv_solidarites_lieu_id, name: "DITP", address: "7 avenue de Ségur" } }

            it "raises an error" do
              expect { subject }.to raise_error(
                WebhookProcessingJobError, "Lieu in webhook is not coherent. #{lieu_attributes}"
              )
            end
          end
        end
      end

      context "when it is a prescribed rdv" do
        let!(:motif_attributes) do
          {
            id: 53,
            location_type: "public_office",
            motif_category: { short_name: "rsa_orientation" },
            name: "RSA orientation", collectif: true
          }
        end
        let!(:category_configuration) do
          create(:category_configuration, organisation: organisation, convene_user: true,
                                          motif_category: motif_category)
        end
        let!(:participations_attributes) do
          [
            { id: 998, status: "unknown", created_by: "agent", user: { id: user_id1 },
              created_by_agent_prescripteur: true, created_by_id: agent.rdv_solidarites_agent_id },
            { id: 999, status: "unknown", created_by: "user", user: { id: user_id2 } }
          ]
        end

        it "sets the participations rdv_solidarites_agent_prescripteur_id" do
          expect(UpsertRecordJob).to receive(:perform_async).with(
            "Rdv",
            data,
            {
              participations_attributes: [
                {
                  id: nil,
                  status: "unknown",
                  created_by: "agent",
                  user_id: 3,
                  rdv_solidarites_participation_id: 998,
                  follow_up_id: follow_up.id,
                  convocable: true,
                  rdv_solidarites_agent_prescripteur_id: agent.rdv_solidarites_agent_id
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  follow_up_id: follow_up2.id,
                  convocable: false,
                  rdv_solidarites_agent_prescripteur_id: nil
                }
              ],
              organisation_id: organisation.id,
              agent_ids: [agent.id],
              motif_id: motif.id,
              lieu_id: lieu.id,
              last_webhook_update_received_at: timestamp
            }
          )
          subject
        end
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
