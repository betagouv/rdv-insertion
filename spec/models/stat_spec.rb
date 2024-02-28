describe Stat do
  include_context "with all existing categories"

  describe "instance_methods" do
    # 2 records each time : first record is linked to the department scope, the second is not

    let!(:department) { create(:department) }
    let!(:stat) { build(:stat, statable_type: structure_type, statable_id: structure_id) }
    let(:date) { Time.zone.parse("17/07/2023 12:00") }
    let!(:other_department) { create(:department) }
    let!(:user1) { create(:user, organisations: [organisation], created_at: date) }
    let!(:user2) { create(:user, organisations: [other_organisation], created_at: date) }
    let!(:organisation) { create(:organisation, department: department) }
    let!(:configuration) { create(:configuration, organisation: organisation) }
    let!(:organisation_with_no_configuration) { create(:organisation, department: department) }
    let!(:other_organisation) { create(:organisation, department: other_department) }
    let!(:other_configuration) { create(:configuration, organisation: other_organisation) }
    let!(:motif) { create(:motif, collectif: false) }
    let!(:motif_collectif) { create(:motif, collectif: true) }
    let!(:rdv1) { create(:rdv, organisation: organisation, created_by: "user", motif: motif, starts_at: date) }
    let!(:rdv2) { create(:rdv, organisation: other_organisation, created_by: "user", motif: motif) }
    let!(:invitation1) do
      create(:invitation, user: user1, department: department, organisations: [organisation],
                          created_at: date, rdv_context: rdv_context1)
    end
    let!(:invitation2) do
      create(:invitation, user: user2, department: other_department, organisations: [other_organisation],
                          created_at: date, rdv_context: rdv_context2)
    end
    let!(:agent1) { create(:agent, organisations: [organisation], last_sign_in_at: Time.zone.now) }
    let!(:agent2) { create(:agent, organisations: [other_organisation], last_sign_in_at: Time.zone.now) }
    let!(:participation1) { create(:participation, rdv: rdv1, user: user1, rdv_context: rdv_context1) }
    let!(:participation2) { create(:participation, rdv: rdv2, user: user2, rdv_context: rdv_context2) }
    let!(:rdv_context1) { create(:rdv_context, user: user1, motif_category: category_rsa_orientation) }
    let!(:rdv_context2) { create(:rdv_context, user: user2, motif_category: category_rsa_orientation) }
    let!(:structure_type) { "Department" }
    let!(:structure_id) { department.id }

    context "when statable type is Department and statable_id is present" do
      describe "#all_users" do
        it "scopes the collection to the department" do
          expect(stat.all_users).to include(user1)
          expect(stat.all_users).not_to include(user2)
        end
      end

      describe "#all_organisations" do
        it "scopes the collection to the department" do
          expect(stat.all_organisations).to include(organisation)
          expect(stat.all_organisations).not_to include(other_organisation)
        end
      end

      describe "#all_participations" do
        it "scopes the collection to the department" do
          expect(stat.all_participations).to include(participation1)
          expect(stat.all_participations).not_to include(participation2)
        end
      end

      describe "#invitations_set" do
        it "scopes the collection to the department" do
          expect(stat.invitations_set).to include(invitation1)
          expect(stat.invitations_set).not_to include(invitation2)
        end
      end

      describe "#participations_set" do
        it "scopes the collection to the department" do
          expect(stat.participations_set).to include(participation1)
          expect(stat.participations_set).not_to include(participation2)
        end
      end

      describe "participations scopes for noshows" do
        # participation with notification
        let!(:participation3) { create(:participation, rdv: rdv3, user: user1) }
        let!(:rdv3) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:notification) { create(:notification, participation: participation3) }
        # participation without neither notification nor invitation
        let!(:participation4) { create(:participation, rdv: rdv4, user: user1) }
        let!(:rdv4) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        # participation with notification and invitation
        let!(:participation5) { create(:participation, rdv: rdv5, user: user1) }
        let!(:rdv5) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let(:invitation_for_participation5) do
          create(:invitation, user: user1, department: department, organisations: [organisation],
                              created_at: date, rdv_context: rdv_context1)
        end
        let!(:notification_for_participation5) { create(:notification, participation: participation5) }

        describe "#participations_after_invitations_set" do
          it "scopes the collection to the department" do
            expect(stat.participations_after_invitations_set).to include(participation1)
            expect(stat.participations_after_invitations_set).not_to include(participation2)
            expect(stat.participations_after_invitations_set).not_to include(participation3)
            expect(stat.participations_after_invitations_set).not_to include(participation4)
            expect(stat.participations_after_invitations_set).not_to include(participation5)
          end
        end

        describe "#participations_with_notifications_set" do
          it "scopes the collection to the department" do
            expect(stat.participations_with_notifications_set).not_to include(participation1)
            expect(stat.participations_with_notifications_set).not_to include(participation2)
            expect(stat.participations_with_notifications_set).to include(participation3)
            expect(stat.participations_with_notifications_set).not_to include(participation4)
            expect(stat.participations_with_notifications_set).to include(participation5)
          end
        end
      end

      describe "#users_set" do
        let!(:user3) do
          create(:user, organisations: [organisation], deleted_at: date)
        end
        let!(:user4) do
          create(:user, organisations: [organisation])
        end
        let!(:archive) { create(:archive, user: user4, department: department) }
        let!(:user5) do
          create(:user, organisations: [organisation_with_no_configuration])
        end

        it "scopes the collection to the department" do
          expect(stat.users_set).to include(user1)
          expect(stat.users_set).not_to include(user2)
        end

        it "does not include the deleted users" do
          expect(stat.users_set).not_to include(user3)
        end

        it "does not include the archived users" do
          expect(stat.users_set).not_to include(user4)
        end
      end

      describe "#agents_set" do
        let!(:agent3) do
          create(:agent, organisations: [organisation], last_sign_in_at: Time.zone.now, email: "a@beta.gouv.fr")
        end
        let!(:agent4) { create(:agent, organisations: [organisation], last_sign_in_at: nil) }

        it "scopes the collection to the department" do
          expect(stat.agents_set).to include(agent1)
          expect(stat.agents_set).not_to include(agent2)
        end

        it "does not include the betagouv agents" do
          expect(stat.agents_set).not_to include(agent3)
        end

        it "does not include the agents who never logged in" do
          expect(stat.agents_set).not_to include(agent4)
        end
      end

      describe "#rdv_contexts_with_invitations_and_participations_set" do
        let!(:user3) { create(:user, organisations: [organisation]) }
        let!(:rdv3) { create(:rdv, organisation: organisation) }
        let!(:participation3) { create(:participation, rdv: rdv3, rdv_context: rdv_context3) }
        let!(:rdv_context3) { create(:rdv_context, user: user3) }
        let!(:user4) { create(:user, organisations: [organisation]) }
        let!(:invitation4) { create(:invitation, rdv_context: rdv_context4) }
        let!(:rdv4) { create(:rdv, organisation: organisation) }
        let!(:participation4) { create(:participation, rdv: rdv4, rdv_context: rdv_context4) }
        let!(:rdv_context4) { create(:rdv_context, user: user4) }
        let!(:user5) { create(:user, organisations: [organisation]) }
        let!(:invitation5) { create(:invitation, rdv_context: rdv_context5) }
        let!(:rdv_context5) { create(:rdv_context, user: user5) }
        let!(:user6) do
          create(:user, organisations: [organisation_with_no_configuration])
        end
        let!(:invitation6) { create(:invitation, created_at: date, rdv_context: rdv_context6) }
        let!(:rdv6) { create(:rdv, organisation: organisation) }
        let!(:participation6) { create(:participation, rdv: rdv6, rdv_context: rdv_context6) }
        let!(:rdv_context6) { create(:rdv_context, user: user6) }

        it "scopes the collection to the department" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).to include(rdv_context1)
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context2)
        end

        it "does not include rdv_contexts with no invitations" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context3)
        end

        it "does not include rdv_contexts with no rdvs" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context5)
        end
      end

      describe "#rdvs_non_collectifs_set" do
        let!(:user3) do
          create(:user, organisations: [organisation])
        end
        let!(:rdv3) { create(:rdv, organisation: organisation, motif: motif_collectif) }
        let!(:participation3) { create(:participation, rdv: rdv3, user: user3) }

        it "does not include collectifs rdvs" do
          expect(stat.rdvs_non_collectifs_set).not_to include(rdv3)
        end
      end

      describe "#invited_users_set" do
        let!(:user3) do
          create(:user, organisations: [organisation_with_no_configuration])
        end
        let!(:user4) { create(:user, organisations: [organisation]) }
        let!(:user5) { create(:user, organisations: [organisation]) }
        let!(:user6) { create(:user, organisations: [organisation]) }
        let!(:invitation3) { create(:invitation, user: user3, department: department, created_at: date) }
        let!(:invitation5) { create(:invitation, user: user5, department: department) }
        let!(:invitation6) { create(:invitation, user: user6, department: department, created_at: date) }
        let!(:rdv3) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:rdv4) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:rdv5) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:participation3) { create(:participation, rdv: rdv3, user: user3) }
        let!(:participation4) { create(:participation, rdv: rdv4, user: user4) }
        let!(:participation5) { create(:participation, rdv: rdv5, user: user5) }

        it "scopes the collection to the department" do
          expect(stat.invited_users_set).to include(user1)
          expect(stat.invited_users_set).not_to include(user2)
        end

        it "does not include the users whith no invitations" do
          expect(stat.invited_users_set).not_to include(user4)
        end

        it "includes the invited users whith no rdvs" do
          expect(stat.invited_users_set).to include(user6)
        end
      end

      describe "#users_first_orientation_rdv_context" do
        let!(:first_user) do
          create(:user, organisations: [organisation])
        end
        let!(:second_user) { create(:user, organisations: [organisation]) }
        let!(:third_user) do
          create(:user, organisations: [organisation])
        end
        let!(:first_user_first_orientation_rdv_context) do
          create(
            :rdv_context,
            user: first_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end
        let!(:first_user_second_orientation_rdv_context) do
          create(
            :rdv_context,
            user: first_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end

        let!(:second_user_orientation_rdv_context) do
          create(
            :rdv_context,
            user: second_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end

        let!(:third_user_rdv_context_not_orientation) do
          create(
            :rdv_context,
            user: third_user,
            motif_category: create(:motif_category, leads_to_orientation: false)
          )
        end

        it "retrieves the first orientation rdv_context of each user" do
          expect(stat.users_first_orientation_rdv_context).to include(first_user_first_orientation_rdv_context)
          expect(stat.users_first_orientation_rdv_context).to include(second_user_orientation_rdv_context)
          expect(stat.users_first_orientation_rdv_context).not_to include(first_user_second_orientation_rdv_context)
          expect(stat.users_first_orientation_rdv_context).not_to include(third_user_rdv_context_not_orientation)
        end
      end

      describe "#orientation_rdv_contexts_with_invitations" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:rdv_context3) do
          create(:rdv_context, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the department" do
          expect(stat.orientation_rdv_contexts_with_invitations).to include(rdv_context1)
          expect(stat.orientation_rdv_contexts_with_invitations).not_to include(rdv_context2)
        end

        it "does not include the rdv_contexts with no motif category for a first rdv RSA" do
          expect(stat.orientation_rdv_contexts_with_invitations).not_to include(rdv_context3)
        end
      end
    end

    context "when statable type is Organisation and statable_id is present" do
      let!(:structure_type) { "Organisation" }
      let!(:structure_id) { organisation.id }

      describe "#all_users" do
        it "scopes the collection to the organisation" do
          expect(stat.all_users).to include(user1)
          expect(stat.all_users).not_to include(user2)
        end
      end

      describe "#all_organisations" do
        it "scopes the collection to the organisation" do
          expect(stat.all_organisations).to include(organisation)
          expect(stat.all_organisations).not_to include(other_organisation)
        end
      end

      describe "#all_participations" do
        it "scopes the collection to the organisation" do
          expect(stat.all_participations).to include(participation1)
          expect(stat.all_participations).not_to include(participation2)
        end
      end

      describe "#invitations_set" do
        it "scopes the collection to the organisation" do
          expect(stat.invitations_set).to include(invitation1)
          expect(stat.invitations_set).not_to include(invitation2)
        end
      end

      describe "#participations_set" do
        it "scopes the collection to the organisation" do
          expect(stat.participations_set).to include(participation1)
          expect(stat.participations_set).not_to include(participation2)
        end
      end

      describe "#users_set" do
        let!(:user3) do
          create(:user, organisations: [organisation], deleted_at: date)
        end
        let!(:user4) do
          create(:user, organisations: [organisation])
        end
        let!(:archive) { create(:archive, user: user4, department: department) }
        let!(:user5) do
          create(:user, organisations: [organisation_with_no_configuration])
        end

        it "scopes the collection to the organisation" do
          expect(stat.users_set).to include(user1)
          expect(stat.users_set).not_to include(user2)
        end

        it "does not include the deleted users" do
          expect(stat.users_set).not_to include(user3)
        end

        it "does not include the archived users" do
          expect(stat.users_set).not_to include(user4)
        end

        it "does not include the user from irrelevant organisations" do
          expect(stat.users_set).not_to include(user5)
        end
      end

      describe "#agents_set" do
        let!(:agent3) do
          create(:agent, organisations: [organisation], last_sign_in_at: Time.zone.now, email: "a@beta.gouv.fr")
        end
        let!(:agent4) { create(:agent, organisations: [organisation], last_sign_in_at: nil) }

        it "scopes the collection to the organisation" do
          expect(stat.agents_set).to include(agent1)
          expect(stat.agents_set).not_to include(agent2)
        end

        it "does not include the betagouv agents" do
          expect(stat.agents_set).not_to include(agent3)
        end

        it "does not include the agents who never logged in" do
          expect(stat.agents_set).not_to include(agent4)
        end
      end

      describe "#rdv_contexts_with_invitations_and_participations_set" do
        let!(:user3) { create(:user, organisations: [organisation]) }
        let!(:rdv3) { create(:rdv, organisation: organisation) }
        let!(:participation3) { create(:participation, rdv: rdv3, rdv_context: rdv_context3) }
        let!(:rdv_context3) { create(:rdv_context, user: user3) }
        let!(:user4) { create(:user, organisations: [organisation]) }
        let!(:invitation4) { create(:invitation, rdv_context: rdv_context4) }
        let!(:rdv4) { create(:rdv, organisation: organisation) }
        let!(:participation4) { create(:participation, rdv: rdv4, rdv_context: rdv_context4) }
        let!(:rdv_context4) { create(:rdv_context, user: user4) }
        let!(:user5) { create(:user, organisations: [organisation]) }
        let!(:invitation5) { create(:invitation, rdv_context: rdv_context5) }
        let!(:rdv_context5) { create(:rdv_context, user: user5) }
        let!(:user6) do
          create(:user, organisations: [organisation_with_no_configuration])
        end
        let!(:invitation6) { create(:invitation, created_at: date, rdv_context: rdv_context6) }
        let!(:rdv6) { create(:rdv, organisation: organisation) }
        let!(:participation6) { create(:participation, rdv: rdv6, rdv_context: rdv_context6) }
        let!(:rdv_context6) { create(:rdv_context, user: user6) }

        it "scopes the collection to the organisation" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).to include(rdv_context1)
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context2)
        end

        it "does not include rdv_contexts with no invitations" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context3)
        end

        it "does not include rdv_contexts with no rdvs" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context5)
        end

        it "does not include the rdv_contexts of users from irrelevant organisations" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).not_to include(rdv_context6)
        end
      end

      describe "#rdvs_non_collectifs_set" do
        let!(:user3) do
          create(:user, organisations: [organisation])
        end
        let!(:rdv3) { create(:rdv, organisation: organisation, motif: motif_collectif) }
        let!(:participation3) { create(:participation, rdv: rdv3, user: user3) }

        it "does not include collectifs rdvs" do
          expect(stat.rdvs_non_collectifs_set).not_to include(rdv3)
        end
      end

      describe "#invited_users_set" do
        let!(:user3) do
          create(:user, organisations: [organisation_with_no_configuration])
        end
        let!(:user4) { create(:user, organisations: [organisation]) }
        let!(:user5) { create(:user, organisations: [organisation]) }
        let!(:user6) { create(:user, organisations: [organisation]) }
        let!(:invitation3) { create(:invitation, user: user3, department: department, created_at: date) }
        let!(:invitation5) { create(:invitation, user: user5, department: department) }
        let!(:invitation6) { create(:invitation, user: user6, department: department, created_at: date) }
        let!(:rdv3) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:rdv4) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:rdv5) { create(:rdv, organisation: organisation, created_by: "user", motif: motif) }
        let!(:participation3) { create(:participation, rdv: rdv3, user: user3) }
        let!(:participation4) { create(:participation, rdv: rdv4, user: user4) }
        let!(:participation5) { create(:participation, rdv: rdv5, user: user5) }

        it "scopes the collection to the organisation" do
          expect(stat.invited_users_set).to include(user1)
          expect(stat.invited_users_set).not_to include(user2)
        end

        it "does not include the user from irrelevant organisations" do
          expect(stat.invited_users_set).not_to include(user3)
        end

        it "does not include the users whith no invitations" do
          expect(stat.invited_users_set).not_to include(user4)
        end

        it "includes the users whith no rdvs" do
          expect(stat.invited_users_set).to include(user6)
        end
      end

      describe "#users_first_orientation_rdv_context" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:rdv_context3) do
          create(:rdv_context, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the organisation" do
          expect(stat.users_first_orientation_rdv_context).to include(rdv_context1)
          expect(stat.users_first_orientation_rdv_context).not_to include(rdv_context2)
        end

        it "does not include the rdv_context that do not lead to orientation" do
          expect(stat.users_first_orientation_rdv_context).not_to include(rdv_context3)
        end
      end

      describe "#orientation_rdv_contexts_with_invitations" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:rdv_context3) do
          create(:rdv_context, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the organisation" do
          expect(stat.orientation_rdv_contexts_with_invitations).to include(rdv_context1)
          expect(stat.orientation_rdv_contexts_with_invitations).not_to include(rdv_context2)
        end

        it "does not include the rdv_contexts with no motif category for a first rdv RSA" do
          expect(stat.orientation_rdv_contexts_with_invitations).not_to include(rdv_context3)
        end
      end
    end

    context "when it is the stat record for all departments" do
      let!(:stat) { build(:stat, statable_type: "Department", statable_id: nil) }

      describe "#all_users" do
        it "does not scope the collection to the department" do
          expect(stat.all_users).to include(user2)
        end
      end

      describe "#all_organisations" do
        it "does not scope the collection to the department" do
          expect(stat.all_organisations).to include(other_organisation)
        end
      end

      describe "#all_participations" do
        it "does not scope the collection to the department" do
          expect(stat.all_participations).to include(participation2)
        end
      end

      describe "#invitations_set" do
        it "does not scope the collection to the department" do
          expect(stat.invitations_set).to include(invitation2)
        end
      end

      describe "#participations_set" do
        it "does not scope the collection to the department" do
          expect(stat.participations_set).to include(participation2)
        end
      end

      describe "#users_set" do
        it "does not scope the collection to the department" do
          expect(stat.users_set).to include(user2)
        end
      end

      describe "#agents_set" do
        it "does not scope the collection to the department" do
          expect(stat.agents_set).to include(agent1)
          expect(stat.agents_set).to include(agent2)
        end
      end

      describe "#rdv_contexts_with_invitations_and_participations_set" do
        it "does not scope the collection to the department" do
          expect(stat.rdv_contexts_with_invitations_and_participations_set).to include(rdv_context2)
        end
      end

      describe "#invited_users_set" do
        it "does not scope the collection to the department" do
          expect(stat.invited_users_set).to include(user2)
        end
      end

      describe "#users_with_orientation_category_set" do
        it "does not scope the collection to the department" do
          expect(stat.users_first_orientation_rdv_context).to include(rdv_context2)
        end
      end

      describe "#orientation_rdv_contexts_with_invitations" do
        it "does not scope the collection to the department" do
          expect(stat.orientation_rdv_contexts_with_invitations).to include(rdv_context2)
        end
      end
    end
  end
end
