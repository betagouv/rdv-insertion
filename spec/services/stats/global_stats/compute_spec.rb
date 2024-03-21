describe Stats::GlobalStats::Compute, type: :service do
  subject { described_class.call(stat: stat) }

  let!(:stat) { create(:stat, statable_type: "Department", statable_id: department.id) }

  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:user1) { create(:user, organisations: [organisation]) }
  let!(:user2) { create(:user, organisations: [organisation]) }
  let!(:rdv1) { create(:rdv, organisation: organisation) }
  let!(:rdv2) { create(:rdv, organisation: organisation) }
  let!(:participation1) { create(:participation, rdv: rdv1) }
  let!(:participation2) { create(:participation, rdv: rdv2) }
  let!(:notification) { create(:notification, participation: participation2) }
  let!(:follow_up1) { create(:follow_up, user: user1) }
  let!(:follow_up2) { create(:follow_up, user: user2) }
  let!(:invitation1) { create(:invitation, department: department) }
  let!(:invitation2) { create(:invitation, department: department) }
  let!(:agent) { create(:agent, organisations: [organisation]) }

  describe "#call" do
    before do
      allow(stat).to receive_messages(
        all_users: User.where(id: [user1, user2]),
        all_participations: Participation.where(id: [participation1, participation2]),
        invitations_set: Invitation.where(id: [invitation1, invitation2]),
        participations_after_invitations_set: Participation.where(id: [participation1]),
        participations_with_notifications_set: Participation.where(id: [participation2]),
        follow_ups_with_invitations_and_participations_set: FollowUp.where(id: [follow_up1, follow_up2]),
        users_set: User.where(id: [user1, user2]),
        users_first_orientation_follow_up: FollowUp.where(id: [follow_up1, follow_up2]),
        orientation_follow_ups_with_invitations: FollowUp.where(id: [follow_up1, follow_up2]),
        invited_users_set: User.where(id: [user1, user2]),
        agents_set: Agent.where(id: [agent]),
        user_ids_with_rdv_set: Participation.where(id: [participation1, participation2]).select(:user_id)
      )
      allow(Stats::ComputeRateOfNoShow).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
      allow(Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 4.0))
      allow(Stats::ComputeRateOfRdvSeenInLessThanNDays).to receive(:call)
        .with(follow_ups: stat.users_first_orientation_follow_up, number_of_days: 30)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
      allow(Stats::ComputeRateOfRdvSeenInLessThanNDays).to receive(:call)
        .with(follow_ups: stat.users_first_orientation_follow_up, number_of_days: 15)
        .and_return(OpenStruct.new(success?: true, value: 25.0))
      allow(Stats::ComputeRateOfUsersWithRdvSeen).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
      allow(Stats::ComputeRateOfAutonomousUsers).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    it "renders a hash of stats" do
      expect(subject.stat_attributes).to be_a(Hash)
    end

    it "renders all the stats" do
      expect(subject.stat_attributes).to include(:users_count)
      expect(subject.stat_attributes).to include(:users_with_rdv_count)
      expect(subject.stat_attributes).to include(:rdvs_count)
      expect(subject.stat_attributes).to include(:sent_invitations_count)
      expect(subject.stat_attributes).to include(:rate_of_no_show_for_invitations)
      expect(subject.stat_attributes).to include(:rate_of_no_show_for_convocations)
      expect(subject.stat_attributes).to include(:average_time_between_invitation_and_rdv_in_days)
      expect(subject.stat_attributes).to include(:rate_of_users_oriented_in_less_than_30_days)
      expect(subject.stat_attributes).to include(:rate_of_users_oriented_in_less_than_15_days)
      expect(subject.stat_attributes).to include(:rate_of_users_oriented)
      expect(subject.stat_attributes).to include(:rate_of_autonomous_users)
      expect(subject.stat_attributes).to include(:agents_count)
    end

    it "renders the stats in the right format" do
      expect(subject.stat_attributes[:users_count]).to be_a(Integer)
      expect(subject.stat_attributes[:users_with_rdv_count]).to be_a(Integer)
      expect(subject.stat_attributes[:rdvs_count]).to be_a(Integer)
      expect(subject.stat_attributes[:sent_invitations_count]).to be_a(Integer)
      expect(subject.stat_attributes[:rate_of_no_show_for_invitations]).to be_a(Float)
      expect(subject.stat_attributes[:rate_of_no_show_for_convocations]).to be_a(Float)
      expect(subject.stat_attributes[:average_time_between_invitation_and_rdv_in_days]).to be_a(Float)
      expect(subject.stat_attributes[:rate_of_users_oriented_in_less_than_30_days]).to be_a(Float)
      expect(subject.stat_attributes[:rate_of_users_oriented_in_less_than_15_days]).to be_a(Float)
      expect(subject.stat_attributes[:rate_of_users_oriented]).to be_a(Float)
      expect(subject.stat_attributes[:rate_of_autonomous_users]).to be_a(Float)
      expect(subject.stat_attributes[:agents_count]).to be_a(Integer)
    end

    it "counts the users" do
      expect(stat).to receive(:all_users)
      expect(subject.stat_attributes[:users_count]).to eq(2)
    end

    it "counts the users with rdv" do
      expect(stat).to receive(:user_ids_with_rdv_set)
      expect(subject.stat_attributes[:users_with_rdv_count]).to eq(2)
    end

    it "counts the rdvs" do
      expect(stat).to receive(:all_participations)
      expect(subject.stat_attributes[:rdvs_count]).to eq(2)
    end

    it "counts the sent invitations" do
      expect(stat).to receive(:invitations_set)
      expect(subject.stat_attributes[:sent_invitations_count]).to eq(2)
    end

    it "computes the percentage of no show for invitations" do
      expect(stat).to receive(:participations_after_invitations_set)
      expect(Stats::ComputeRateOfNoShow).to receive(:call)
        .with(participations: [participation1])
      subject
    end

    it "computes the percentage of no show for convocations" do
      expect(stat).to receive(:participations_with_notifications_set)
      expect(Stats::ComputeRateOfNoShow).to receive(:call)
        .with(participations: [participation2])
      subject
    end

    it "computes the average time between first invitation and first rdv in days" do
      expect(stat).to receive(:follow_ups_with_invitations_and_participations_set)
      expect(Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays).to receive(:call)
        .with(follow_ups: [follow_up1, follow_up2])
      subject
    end

    it "computes the percentage of users with rdv seen in less than 30 days" do
      expect(stat).to receive(:users_first_orientation_follow_up)
      expect(Stats::ComputeRateOfRdvSeenInLessThanNDays).to receive(:call)
        .with(follow_ups: [follow_up1, follow_up2], number_of_days: 30)
      expect(subject.stat_attributes[:rate_of_users_oriented_in_less_than_30_days]).to eq(50.0)
    end

    it "computes the percentage of users with rdv seen in less than 15 days" do
      expect(stat).to receive(:users_first_orientation_follow_up)
      expect(Stats::ComputeRateOfRdvSeenInLessThanNDays).to receive(:call)
        .with(follow_ups: [follow_up1, follow_up2], number_of_days: 15)
      expect(subject.stat_attributes[:rate_of_users_oriented_in_less_than_15_days]).to eq(25.0)
    end

    it "computes the percentage of users oriented" do
      expect(stat).to receive(:orientation_follow_ups_with_invitations)
      expect(Stats::ComputeRateOfUsersWithRdvSeen).to receive(:call)
        .with(follow_ups: [follow_up1, follow_up2])
      subject
    end

    it "computes the percentage of invited users with at least on rdv taken in autonomy" do
      expect(stat).to receive(:invited_users_set)
      expect(Stats::ComputeRateOfAutonomousUsers).to receive(:call)
        .with(users: [user1, user2])
      subject
    end

    it "counts the agents" do
      expect(stat).to receive(:agents_set)
      expect(subject.stat_attributes[:agents_count]).to eq(1)
    end
  end
end
