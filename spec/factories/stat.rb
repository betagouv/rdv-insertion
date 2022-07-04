FactoryBot.define do
  factory :stat do
    applicants_count { 0 }
    applicants_count_grouped_by_month { {} }
    rdvs_count { 0 }
    rdvs_count_grouped_by_month { {} }
    sent_invitations_count { 0 }
    sent_invitations_count_grouped_by_month { {} }
    percentage_of_no_show { 0.0 }
    percentage_of_no_show_grouped_by_month { {} }
    average_time_between_invitation_and_rdv_in_days { 0.0 }
    average_time_between_invitation_and_rdv_in_days_by_month { {} }
    average_time_between_rdv_creation_and_start_in_days { 0.0 }
    average_time_between_rdv_creation_and_start_in_days_by_month { {} }
    rate_of_applicants_with_rdv_seen_in_less_than_30_days { 0.0 }
    rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month { {} }
    rate_of_applicants_autonomy { 0.0 }
    rate_of_applicants_autonomy_grouped_by_month { {} }
    agents_count { 1 }
    sequence(:department_number)
  end
end
