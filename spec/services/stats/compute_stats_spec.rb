describe Stats::ComputeStats, type: :service do
  subject { described_class.call(department_number: department.number) }

  before { travel_to("2022-06-10".to_time) }

  let!(:configuration) { create(:configuration, notify_applicant: false) }
  let!(:configuration_notify) { create(:configuration, notify_applicant: true) }
  let!(:department) { create(:department) }
  let!(:relevant_organisation) { create(:organisation, configurations: [configuration], department: department) }
  let!(:irrelevant_organisation) do
    create(:organisation, configurations: [configuration_notify], department: department)
  end

  let!(:rdv_context_orientation) do
    create(:rdv_context, motif_category: "rsa_orientation", created_at: DateTime.new(2022, 4, 4, 10, 0))
  end
  let!(:rdv_context_accompagnement) { create(:rdv_context, motif_category: "rsa_accompagnement") }
  let!(:rdv_context_accompagnement2) do
    create(
      :rdv_context, motif_category: "rsa_accompagnement", created_at: DateTime.new(2022, 5, 7, 10, 0)
    )
  end

  let!(:relevant_agent) { create(:agent, organisations: [relevant_organisation]) }
  let!(:irrelevant_agent) { create(:agent) }

  let!(:invitation) do
    create(:invitation, sent_at: DateTime.new(2022, 4, 4, 10, 0), rdv_context: rdv_context_orientation,
                        department: department)
  end
  let!(:invitation2) do
    create(:invitation, sent_at: DateTime.new(2022, 5, 7, 10, 0), rdv_context: rdv_context_accompagnement2,
                        department: department)
  end
  let!(:invitation_not_sended) { create(:invitation, sent_at: nil, department: department) }

  let!(:orientation_rdv) do
    create(:rdv, rdv_contexts: [rdv_context_orientation], organisation: relevant_organisation,
                 created_at: DateTime.new(2022, 4, 7, 10, 0),
                 starts_at: DateTime.new(2022, 4, 8, 10, 0),
                 created_by: "user",
                 status: "seen")
  end
  let!(:orientation_rdv2) do
    create(:rdv, rdv_contexts: [rdv_context_orientation], organisation: relevant_organisation,
                 created_at: DateTime.new(2022, 5, 2, 10, 0),
                 starts_at: DateTime.new(2022, 5, 7, 10, 0),
                 status: "noshow")
  end
  let!(:accompagnement_rdv) do
    create(:rdv, rdv_contexts: [rdv_context_accompagnement], organisation: relevant_organisation)
  end
  let!(:accompagnement_rdv2) do
    create(:rdv, rdv_contexts: [rdv_context_accompagnement2], organisation: relevant_organisation,
                 created_at: DateTime.new(2022, 5, 8, 10, 0),
                 starts_at: DateTime.new(2022, 5, 11, 10, 0))
  end
  let!(:irrelevant_rdv) { create(:rdv, organisation: relevant_organisation) }
  let!(:irrelevant_rdv2) { create(:rdv, organisation: relevant_organisation) }
  let!(:irrelevant_rdv3) { create(:rdv, organisation: relevant_organisation) }

  let!(:relevant_applicant) do
    create(:applicant, organisations: [relevant_organisation],
                       department: department,
                       rdvs: [orientation_rdv, accompagnement_rdv],
                       rdv_contexts: [rdv_context_orientation],
                       created_at: DateTime.new(2022, 4, 1, 10, 0))
  end
  let!(:relevant_orientation_platform_applicant) do
    create(:applicant, organisations: [relevant_organisation, irrelevant_organisation],
                       department: department,
                       rdvs: [orientation_rdv2, accompagnement_rdv2],
                       rdv_contexts: [rdv_context_accompagnement2],
                       created_at: DateTime.new(2022, 3, 1, 10, 0))
  end
  let!(:irrelevant_applicant) do
    create(:applicant, organisations: [irrelevant_organisation],
                       department: department,
                       rdvs: [irrelevant_rdv],
                       rdv_contexts: [rdv_context_accompagnement],
                       created_at: DateTime.new(2022, 4, 1, 10, 0))
  end
  let!(:irrelevant_applicant2) do
    create(:applicant, organisations: [relevant_organisation], department: department,
                       deleted_at: 2.days.ago, rdvs: [irrelevant_rdv2],
                       created_at: DateTime.new(2022, 5, 1, 10, 0))
  end
  let!(:irrelevant_applicant3) do
    create(:applicant, organisations: [relevant_organisation], department: department, is_archived: true,
                       rdvs: [irrelevant_rdv3], created_at: DateTime.new(2022, 5, 1, 10, 0))
  end

  describe "#call" do
    it "is a success" do
      expect(subject.success?).to eq(true)
    end

    it "renders a hash of stats" do
      expect(subject.data).to be_a(Hash)
    end

    it "renders all the stats" do
      expect(subject.data).to include(:department_number)
      expect(subject.data).to include(:applicants_count)
      expect(subject.data).to include(:applicants_count_grouped_by_month)
      expect(subject.data).to include(:rdvs_count)
      expect(subject.data).to include(:rdvs_count_grouped_by_month)
      expect(subject.data).to include(:sent_invitations_count)
      expect(subject.data).to include(:sent_invitations_count_grouped_by_month)
      expect(subject.data).to include(:percentage_of_no_show)
      expect(subject.data).to include(:percentage_of_no_show_grouped_by_month)
      expect(subject.data).to include(:average_time_between_invitation_and_rdv_in_days)
      expect(subject.data).to include(:average_time_between_invitation_and_rdv_in_days_by_month)
      expect(subject.data).to include(:average_time_between_rdv_creation_and_start_in_days)
      expect(subject.data).to include(:average_time_between_rdv_creation_and_start_in_days_by_month)
      expect(subject.data).to include(:rate_of_applicants_with_rdv_seen_in_less_than_30_days)
      expect(subject.data).to include(:rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month)
      expect(subject.data).to include(:rate_of_applicants_autonomy)
      expect(subject.data).to include(:rate_of_applicants_autonomy_grouped_by_month)
      expect(subject.data).to include(:agents_count)
    end

    describe "#agents_count" do
      it "counts the agents" do
        expect(subject.data[:agents_count]).to eq(1)
      end
    end

    describe "#applicants_count" do
      it "counts the applicants" do
        expect(subject.data[:applicants_count]).to eq(5)
      end
    end

    describe "#applicants_count_grouped_by_month" do
      it "count the applicants month by month" do
        expect(subject.data[:applicants_count_grouped_by_month]).to eq({ "03/2022" => 1, "04/2022" => 2,
                                                                         "05/2022" => 2 })
      end
    end

    describe "#rdvs_count" do
      it "counts the rdvs" do
        expect(subject.data[:rdvs_count]).to eq(7)
      end
    end

    describe "#rdvs_count_grouped_by_month" do
      it "counts the rdvs month by month" do
        expect(subject.data[:rdvs_count_grouped_by_month]).to eq({ "04/2022" => 1, "05/2022" => 2 })
      end
    end

    describe "#sent_invitations_count" do
      it "counts the sent invitations" do
        expect(subject.data[:sent_invitations_count]).to eq(2)
      end
    end

    describe "#sent_invitations_count_grouped_by_month" do
      it "counts the sent invitations month by month" do
        expect(subject.data[:sent_invitations_count_grouped_by_month]).to eq({ "06/2022" => 2 })
      end
    end

    describe "#percentage_of_no_show" do
      it "computes the percentage of no_show for rdvs" do
        expect(subject.data[:percentage_of_no_show]).to eq(50.0)
      end
    end

    describe "#percentage_of_no_show_grouped_by_month" do
      it "computes the percentage of no_show for rdvs" do
        expect(subject.data[:percentage_of_no_show_grouped_by_month]).to eq({ "04/2022" => 0, "05/2022" => 100 })
      end
    end

    describe "#average_time_between_invitation_and_rdv_in_days" do
      it "computes the average time between first invitation and first rdv in days" do
        expect(subject.data[:average_time_between_invitation_and_rdv_in_days]).to eq(2)
      end
    end

    describe "#average_time_between_invitation_and_rdv_in_days_by_month" do
      it "computes the average time by month between first invitation and first rdv in days" do
        expect(subject.data[:average_time_between_invitation_and_rdv_in_days_by_month]).to eq({ "04/2022" => 3,
                                                                                                "05/2022" => 1 })
      end
    end

    describe "#average_time_between_rdv_creation_and_start_in_days" do
      it "computes the average time between the creation of the rdvs and the rdvs date in days" do
        expect(subject.data[:average_time_between_rdv_creation_and_start_in_days]).to eq(3)
      end
    end

    describe "#average_time_between_rdv_creation_and_start_in_days_by_month" do
      it "computes the average time by month between the creation of the rdvs and the rdvs date in days" do
        expect(subject.data[:average_time_between_rdv_creation_and_start_in_days_by_month]).to eq(
          { "04/2022" => 1, "05/2022" => 5 }
        )
      end
    end

    describe "#rate_of_applicants_with_rdv_seen_in_less_than_30_days" do
      it "computes the percentage of applicants with rdv seen in less than 30 days" do
        expect(subject.data[:rate_of_applicants_with_rdv_seen_in_less_than_30_days]).to eq(50)
      end
    end

    describe "#rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month" do
      it "computes the percentage by month of applicants with rdv seen in less than 30 days" do
        expect(subject.data[:rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month]).to eq(
          { "03/2022" => 0, "04/2022" => 100 }
        )
      end
    end

    describe "#rate_of_applicants_autonomy" do
      it "computes the percentage of invited applicants with at least on rdv taken in autonomy" do
        expect(subject.data[:rate_of_applicants_autonomy]).to eq(25)
      end
    end

    describe "#rate_of_applicants_autonomy_grouped_by_month" do
      it "computes the percentage by month of invited applicants with at least on rdv taken in autonomy" do
        expect(subject.data[:rate_of_applicants_autonomy_grouped_by_month]).to eq(
          { "04/2022" => 100, "05/2022" => 0 }
        )
      end
    end
  end
end
