describe RdvSolidaritesWebhooks::ProcessRdvJob do
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
        phone_number: "0755929249", email: nil, birth_date: nil, address: "50 rue Victor Hugo 93500 Pantin" },
      { id: user_id2, first_name: "Jane", last_name: "Campion", created_at: "2021-05-29 14:20:20 +0200",
        email: "jane@campion.com", phone_number: nil, birth_date: nil, address: nil }
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
      "rdvs_users" => participations_attributes,
      "organisation" => { id: rdv_solidarites_organisation_id }
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

  let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation") }
  let!(:configuration) do
    create(:configuration, organisation: organisation, convene_user: false, motif_category: motif_category)
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
      rdv_context: rdv_context,
      sent_at: 2.days.ago,
      valid_until: 3.days.from_now
    )
  end

  let!(:invitation2) do
    create(
      :invitation,
      organisations:
      [organisation],
      rdv_context: rdv_context2,
      sent_at: 2.days.ago,
      valid_until: 3.days.from_now
    )
  end

  let!(:invitation3) do
    create(
      :invitation,
      organisations: [organisation],
      rdv_context: rdv_context,
      sent_at: 4.days.ago,
      valid_until: 3.days.ago
    )
  end

  let!(:rdv_context) do
    build(:rdv_context, motif_category: motif_category, user: user)
  end

  let!(:rdv_context2) do
    build(:rdv_context, motif_category: motif_category, user: user2)
  end

  # rubocop:disable RSpec/ExampleLength
  describe "#perform" do
    before do
      allow(RdvContext).to receive(:find_or_create_by!)
        .with(user: user, motif_category: motif_category)
        .and_return(rdv_context)
      allow(RdvContext).to receive(:find_or_create_by!)
        .with(user: user2, motif_category: motif_category)
        .and_return(rdv_context2)
      allow(UpsertRecordJob).to receive(:perform_async)
      allow(InvalidateInvitationJob).to receive(:perform_async)
      allow(DeleteRdvJob).to receive(:perform_async)
      allow(SendRdvSolidaritesWebhookJob).to receive(:perform_async)
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
            rdv_context_id: rdv_context.id,
            convocable: false
          },
          {
            id: nil,
            status: "unknown",
            created_by: "user",
            user_id: user2.id,
            rdv_solidarites_participation_id: 999,
            rdv_context_id: rdv_context2.id,
            convocable: false
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
          let!(:motif_category) { create(:motif_category, short_name: "rsa_orientation", participation_optional: true) }

          it "does not enqueue a job to invalidate the related sent valid invitations" do
            expect(InvalidateInvitationJob).not_to receive(:perform_async)
            subject
          end
        end

        it "does not change the user count" do
          expect { subject }.not_to change(User, :count)
        end

        context "when one of the user is not yet created" do
          let!(:user_id1) { 555 }

          let!(:new_user) { build(:user, rdv_solidarites_user_id: user_id1) }
          let!(:new_rdv_context) do
            build(:rdv_context, motif_category: motif_category, user: new_user)
          end

          before do
            allow(User).to receive(:create!).and_return(new_user)
            allow(RdvContext).to receive(:find_or_create_by!)
              .with(user: new_user, motif_category: motif_category)
              .and_return(new_rdv_context)
          end

          it "creates the user" do
            expect(User).to receive(:create!).with(
              rdv_solidarites_user_id: user_id1,
              organisations: [organisation],
              first_name: "James",
              last_name: "Cameron",
              address: "50 rue Victor Hugo 93500 Pantin",
              phone_number: "0755929249",
              created_through: "rdv_solidarites"
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
                      rdv_context_id: rdv_context2.id,
                      convocable: false
                    },
                    {
                      id: nil,
                      status: "unknown",
                      created_by: "user",
                      user_id: new_user.id,
                      rdv_solidarites_participation_id: 998,
                      rdv_context_id: new_rdv_context.id,
                      convocable: false
                    }
                  ],
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

      context "for a participation update and destroy" do
        let!(:participations_attributes) do
          [{ id: 999, status: "seen", created_by: "user", user: { id: user_id2 } }]
        end
        let!(:users) { [{ id: user_id2 }] }

        # Rdv create factory create a new user (and participation) by default
        let!(:rdv) { create(:rdv, rdv_solidarites_rdv_id: rdv_solidarites_rdv_id, organisation: organisation) }
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
              rdv_context_id: rdv_context2.id
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

    context "with no matching configuration" do
      let!(:motif_attributes) { { id: 53, location_type: "public_office", category: "rsa_accompagnement" } }

      it "does not call any job" do
        [UpsertRecordJob, DeleteRdvJob].each do |klass|
          expect(klass).not_to receive(:perform_async)
        end
        subject
      end
    end

    context "when there are webhook endpoints associated to the org" do
      let!(:webhook_endpoint) do
        create(:webhook_endpoint, organisations: [organisation])
      end
      let!(:nir) { generate_random_nir }
      let!(:department_internal_id) { "some-dept-id" }
      let!(:user) do
        create(
          :user,
          organisations: [organisation],
          title: "monsieur",
          department_internal_id: department_internal_id,
          nir: nir,
          invitations: [invitation],
          referents: [referent]
        )
      end

      let!(:invitation) { create(:invitation, sent_at: 1.week.ago) }
      let!(:referent) { create(:agent) }

      let!(:user2) do
        create(
          :user,
          organisations: [organisation],
          title: "madame",
          pole_emploi_id: "Z12123",
          archives: [archive],
          tags: [tag]
        )
      end
      let!(:archive) { create(:archive) }
      let!(:tag) { create(:tag) }

      let!(:webhook_payload) do
        {
          data: data.merge(
            users: [
              {
                id: user_id1,
                uid: user.uid,
                affiliation_number: user.affiliation_number,
                role: user.role,
                created_at: "2021-05-29 14:50:22 +0200",
                department_internal_id: department_internal_id,
                first_name: "James",
                last_name: "Cameron",
                address: "50 rue Victor Hugo 93500 Pantin",
                phone_number: "0755929249",
                email: nil,
                title: "monsieur",
                birth_date: nil,
                rights_opening_date: user.rights_opening_date,
                birth_name: nil,
                nir: nir,
                pole_emploi_id: user.pole_emploi_id,
                carnet_de_bord_carnet_id: user.pole_emploi_id,
                invitations: [invitation],
                orientation: nil,
                referents: [referent],
                tags: []
              },
              {
                id: user_id2,
                uid: user2.uid,
                affiliation_number: user2.affiliation_number,
                role: user2.role,
                created_at: "2021-05-29 14:20:20 +0200",
                department_internal_id: user2.department_internal_id,
                first_name: "Jane",
                last_name: "Campion",
                address: nil,
                phone_number: nil,
                email: "jane@campion.com",
                title: "madame",
                birth_date: nil,
                rights_opening_date: user2.rights_opening_date,
                birth_name: nil,
                nir: user2.nir,
                pole_emploi_id: "Z12123",
                carnet_de_bord_carnet_id: user2.carnet_de_bord_carnet_id,
                orientation: nil,
                invitations: [],
                referents: [],
                tags: [tag]
              }
            ]
          ),
          meta:
        }
      end

      it "enqueues a webhook job with an augmented payload" do
        expect(SendRdvSolidaritesWebhookJob).to receive(:perform_async)
          .with(webhook_endpoint.id, webhook_payload)
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
        let!(:configuration) do
          create(:configuration, organisation: organisation, convene_user: true, motif_category: motif_category)
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
                  rdv_context_id: rdv_context.id,
                  convocable: true
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  rdv_context_id: rdv_context2.id,
                  convocable: true
                }
              ],
              organisation_id: organisation.id,
              motif_id: motif.id,
              lieu_id: lieu.id,
              last_webhook_update_received_at: timestamp
            }
          )
          subject
        end

        context "when the configuration does not handle convocations" do
          before { configuration.update! convene_user: false }

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
                    rdv_context_id: rdv_context.id,
                    convocable: false
                  },
                  {
                    id: nil,
                    status: "unknown",
                    created_by: "user",
                    user_id: 4,
                    rdv_solidarites_participation_id: 999,
                    rdv_context_id: rdv_context2.id,
                    convocable: false
                  }
                ],
                organisation_id: organisation.id,
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

      context "when it is a collectif rdv with agent created participations" do
        let!(:motif_attributes) do
          {
            id: 53,
            location_type: "public_office",
            motif_category: { short_name: "rsa_orientation" },
            name: "RSA orientation", collectif: true
          }
        end
        let!(:configuration) do
          create(:configuration, organisation: organisation, convene_user: true, motif_category: motif_category)
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
                  rdv_context_id: rdv_context.id,
                  convocable: true
                },
                {
                  id: nil,
                  status: "unknown",
                  created_by: "user",
                  user_id: 4,
                  rdv_solidarites_participation_id: 999,
                  rdv_context_id: rdv_context2.id,
                  convocable: false
                }
              ],
              organisation_id: organisation.id,
              motif_id: motif.id,
              lieu_id: lieu.id,
              last_webhook_update_received_at: timestamp
            }
          )
          subject
        end

        context "when the configuration does not handle convocations" do
          before { configuration.update! convene_user: false }

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
                    rdv_context_id: rdv_context.id,
                    convocable: false
                  },
                  {
                    id: nil,
                    status: "unknown",
                    created_by: "user",
                    user_id: 4,
                    rdv_solidarites_participation_id: 999,
                    rdv_context_id: rdv_context2.id,
                    convocable: false
                  }
                ],
                organisation_id: organisation.id,
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
    end
  end
end
# rubocop:enable RSpec/ExampleLength
