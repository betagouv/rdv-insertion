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
    let!(:category_configuration) { create(:category_configuration, organisation: organisation) }
    let!(:organisation_with_no_configuration) { create(:organisation, department: department) }
    let!(:other_organisation) { create(:organisation, department: other_department) }
    let!(:other_configuration) { create(:category_configuration, organisation: other_organisation) }
    let!(:motif) { create(:motif, collectif: false) }
    let!(:motif_collectif) { create(:motif, collectif: true) }
    let!(:rdv1) { create(:rdv, organisation: organisation, created_by: "user", motif: motif, starts_at: date) }
    let!(:rdv2) { create(:rdv, organisation: other_organisation, created_by: "user", motif: motif) }
    let!(:invitation1) do
      create(:invitation, user: user1, department: department, organisations: [organisation],
                          created_at: date, follow_up: follow_up1)
    end
    let!(:invitation2) do
      create(:invitation, user: user2, department: other_department, organisations: [other_organisation],
                          created_at: date, follow_up: follow_up2)
    end
    let!(:agent1) { create(:agent, organisations: [organisation], last_sign_in_at: Time.zone.now) }
    let!(:agent2) { create(:agent, organisations: [other_organisation], last_sign_in_at: Time.zone.now) }
    let!(:participation1) { create(:participation, rdv: rdv1, user: user1, follow_up: follow_up1) }
    let!(:participation2) { create(:participation, rdv: rdv2, user: user2, follow_up: follow_up2) }
    let!(:follow_up1) { create(:follow_up, user: user1, motif_category: category_rsa_orientation) }
    let!(:follow_up2) { create(:follow_up, user: user2, motif_category: category_rsa_orientation) }
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
                              created_at: date, follow_up: follow_up1)
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
          create(:user, organisations: [organisation_with_no_configuration])
        end

        it "scopes the collection to the department" do
          expect(stat.users_set).to include(user1)
          expect(stat.users_set).not_to include(user2)
        end

        it "does not include the deleted users" do
          expect(stat.users_set).not_to include(user3)
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

      describe "#users_first_orientation_follow_up" do
        let!(:first_user) do
          create(:user, organisations: [organisation])
        end
        let!(:second_user) { create(:user, organisations: [organisation]) }
        let!(:third_user) do
          create(:user, organisations: [organisation])
        end
        let!(:first_user_first_orientation_follow_up) do
          create(
            :follow_up,
            user: first_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end
        let!(:first_user_second_orientation_follow_up) do
          create(
            :follow_up,
            user: first_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end

        let!(:second_user_orientation_follow_up) do
          create(
            :follow_up,
            user: second_user,
            motif_category: create(:motif_category, leads_to_orientation: true)
          )
        end

        let!(:third_user_follow_up_not_orientation) do
          create(
            :follow_up,
            user: third_user,
            motif_category: create(:motif_category, leads_to_orientation: false)
          )
        end

        it "retrieves the first orientation follow_up of each user" do
          expect(stat.users_first_orientation_follow_up).to include(first_user_first_orientation_follow_up)
          expect(stat.users_first_orientation_follow_up).to include(second_user_orientation_follow_up)
          expect(stat.users_first_orientation_follow_up).not_to include(first_user_second_orientation_follow_up)
          expect(stat.users_first_orientation_follow_up).not_to include(third_user_follow_up_not_orientation)
        end
      end

      describe "#orientation_follow_ups_with_invitations" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:follow_up3) do
          create(:follow_up, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the department" do
          expect(stat.orientation_follow_ups_with_invitations).to include(follow_up1)
          expect(stat.orientation_follow_ups_with_invitations).not_to include(follow_up2)
        end

        it "does not include the follow_ups with no motif category for a first rdv RSA" do
          expect(stat.orientation_follow_ups_with_invitations).not_to include(follow_up3)
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
          create(:user, organisations: [organisation_with_no_configuration])
        end

        it "scopes the collection to the organisation" do
          expect(stat.users_set).to include(user1)
          expect(stat.users_set).not_to include(user2)
        end

        it "does not include the deleted users" do
          expect(stat.users_set).not_to include(user3)
        end

        it "does not include the user from irrelevant organisations" do
          expect(stat.users_set).not_to include(user4)
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

      describe "#users_first_orientation_follow_up" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:follow_up3) do
          create(:follow_up, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the organisation" do
          expect(stat.users_first_orientation_follow_up).to include(follow_up1)
          expect(stat.users_first_orientation_follow_up).not_to include(follow_up2)
        end

        it "does not include the follow_up that do not lead to orientation" do
          expect(stat.users_first_orientation_follow_up).not_to include(follow_up3)
        end
      end

      describe "#orientation_follow_ups_with_invitations" do
        let!(:user3) { create(:user, organisations: [organisation], created_at: date) }
        let!(:follow_up3) do
          create(:follow_up, user: user3, motif_category: category_rsa_cer_signature)
        end

        it "scopes the collection to the organisation" do
          expect(stat.orientation_follow_ups_with_invitations).to include(follow_up1)
          expect(stat.orientation_follow_ups_with_invitations).not_to include(follow_up2)
        end

        it "does not include the follow_ups with no motif category for a first rdv RSA" do
          expect(stat.orientation_follow_ups_with_invitations).not_to include(follow_up3)
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

      describe "#invited_users_set" do
        it "does not scope the collection to the department" do
          expect(stat.invited_users_set).to include(user2)
        end
      end

      describe "#users_with_orientation_category_set" do
        it "does not scope the collection to the department" do
          expect(stat.users_first_orientation_follow_up).to include(follow_up2)
        end
      end

      describe "#orientation_follow_ups_with_invitations" do
        it "does not scope the collection to the department" do
          expect(stat.orientation_follow_ups_with_invitations).to include(follow_up2)
        end
      end
    end
  end
end
