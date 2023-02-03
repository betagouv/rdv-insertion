describe Stats::MonthlyStats::ComputeForFocusedMonth, type: :service do
  subject { described_class.call(stat: stat, date: date) }

  let!(:stat) { create(:stat, department_number: department.number) }
  let!(:date) { 1.month.ago }

  let!(:first_day_of_last_month) { 1.month.ago.beginning_of_month }
  let!(:first_day_of_other_month) { 2.months.ago.beginning_of_month }

  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:applicant1) { create(:applicant, department: department, created_at: first_day_of_last_month) }
  let!(:applicant2) { create(:applicant, department: department, created_at: first_day_of_other_month) }
  let!(:rdv1) { create(:rdv, created_at: first_day_of_last_month, organisation: organisation) }
  let!(:rdv2) { create(:rdv, created_at: first_day_of_other_month, organisation: organisation) }
  let!(:rdv_context1) { create(:rdv_context, created_at: first_day_of_last_month, applicant: applicant1) }
  let!(:rdv_context2) { create(:rdv_context, created_at: first_day_of_other_month, applicant: applicant2) }
  let!(:invitation1) do
    create(:invitation, created_at: first_day_of_last_month, sent_at: first_day_of_last_month, department: department)
  end
  let!(:invitation2) do
    create(:invitation, created_at: first_day_of_other_month, sent_at: first_day_of_other_month, department: department)
  end

  describe "#call" do
    before do
      allow(stat).to receive(:all_applicants)
        .and_return(department.applicants)
      allow(stat).to receive(:all_rdvs)
        .and_return(department.rdvs)
      allow(stat).to receive(:invitations_sample)
        .and_return(department.invitations.sent)
      allow(stat).to receive(:rdvs_sample)
        .and_return(department.rdvs)
      allow(stat).to receive(:rdv_contexts_sample)
        .and_return(department.rdv_contexts)
      allow(stat).to receive(:applicants_sample)
        .and_return(department.applicants)
      allow(stat).to receive(:agents_sample)
        .and_return(department.agents)
      allow(stat).to receive(:applicants_for_30_days_rdvs_seen_sample)
        .and_return(department.applicants)
      allow(stat).to receive(:invited_applicants_sample)
        .and_return(department.applicants)
      allow(stat).to receive(:rdvs_created_by_user_sample)
        .and_return(department.rdvs.select(&:created_by_user?))
      allow(Stats::ComputePercentageOfNoShow).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
      allow(Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 4.0))
      allow(Stats::ComputeAverageTimeBetweenRdvCreationAndStartInDays).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 4.0))
      allow(Stats::ComputeRateOfApplicantsWithRdvSeenInLessThanThirtyDays).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
      allow(Stats::ComputeRateOfAutonomousApplicants).to receive(:call)
        .and_return(OpenStruct.new(success?: true, value: 50.0))
    end

    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    it "renders a hash of stats" do
      expect(subject.stats_values).to be_a(Hash)
    end

    it "renders all the stats" do
      expect(subject.stats_values).to include(:applicants_count_grouped_by_month)
      expect(subject.stats_values).to include(:rdvs_count_grouped_by_month)
      expect(subject.stats_values).to include(:sent_invitations_count_grouped_by_month)
      expect(subject.stats_values).to include(:percentage_of_no_show_grouped_by_month)
      expect(subject.stats_values).to include(:average_time_between_invitation_and_rdv_in_days_by_month)
      expect(subject.stats_values).to include(:average_time_between_rdv_creation_and_start_in_days_by_month)
      expect(subject.stats_values).to include(:rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month)
      expect(subject.stats_values).to include(:rate_of_autonomous_applicants_grouped_by_month)
    end

    it "renders the stats in the right format" do
      expect(subject.stats_values[:applicants_count_grouped_by_month]).to be_a(Integer)
      expect(subject.stats_values[:rdvs_count_grouped_by_month]).to be_a(Integer)
      expect(subject.stats_values[:sent_invitations_count_grouped_by_month]).to be_a(Integer)
      expect(subject.stats_values[:percentage_of_no_show_grouped_by_month]).to be_a(Integer)
      expect(subject.stats_values[:average_time_between_invitation_and_rdv_in_days_by_month]).to be_a(Integer)
      expect(subject.stats_values[:average_time_between_rdv_creation_and_start_in_days_by_month]).to be_a(Integer)
      expect(subject.stats_values[:rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month]).to be_a(Integer)
      expect(subject.stats_values[:rate_of_autonomous_applicants_grouped_by_month]).to be_a(Integer)
    end

    it "counts the applicants for the focused month" do
      expect(stat).to receive(:all_applicants)
      # applicant1 is ok, applicant2 is not created in the focused month
      expect(subject.stats_values[:applicants_count_grouped_by_month]).to eq(1)
    end

    it "counts the rdvs for the focused month" do
      expect(stat).to receive(:all_rdvs)
      # rdv1 is ok, rdv2 is not created in the focused month
      expect(subject.stats_values[:rdvs_count_grouped_by_month]).to eq(1)
    end

    it "counts the sent invitations for the focused month" do
      expect(stat).to receive(:invitations_sample)
      # invitation1 is ok, invitation2 is not sent in the focused month
      expect(subject.stats_values[:sent_invitations_count_grouped_by_month]).to eq(1)
    end

    it "computes the percentage of no show" do
      expect(stat).to receive(:rdvs_sample)
      expect(Stats::ComputePercentageOfNoShow).to receive(:call)
        .with(rdvs: department.rdvs.where(created_at: date.all_month))
      subject
    end

    it "computes the average time between first invitation and first rdv in days" do
      expect(stat).to receive(:rdv_contexts_sample)
      expect(Stats::ComputeAverageTimeBetweenInvitationAndRdvInDays).to receive(:call)
        .with(rdv_contexts: department.rdv_contexts.where(created_at: date.all_month))
      subject
    end

    it "computes the average time between the creation of the rdvs and the rdvs date in days" do
      expect(stat).to receive(:rdvs_sample)
      expect(Stats::ComputeAverageTimeBetweenRdvCreationAndStartInDays).to receive(:call)
        .with(rdvs: department.rdvs.where(created_at: date.all_month))
      subject
    end

    it "computes the percentage of applicants with rdv seen in less than 30 days" do
      expect(stat).to receive(:applicants_for_30_days_rdvs_seen_sample)
      expect(Stats::ComputeRateOfApplicantsWithRdvSeenInLessThanThirtyDays).to receive(:call)
        .with(applicants: department.applicants.where(created_at: date.all_month))
      subject
    end

    it "computes the percentage of invited applicants with at least on rdv taken in autonomy" do
      expect(stat).to receive(:invited_applicants_sample)
      expect(stat).to receive(:rdvs_created_by_user_sample)
      expect(Stats::ComputeRateOfAutonomousApplicants).to receive(:call)
        .with(applicants: department.applicants.where(created_at: date.all_month),
              rdvs: department.rdvs.where(created_at: date.all_month).select(&:created_by_user?))
      subject
    end
  end
end
