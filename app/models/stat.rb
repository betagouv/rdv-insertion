class Stat < ApplicationRecord
  validates :applicants_count, :applicants_count_grouped_by_month, :rdvs_count, :rdvs_count_grouped_by_month,
            :sent_invitations_count, :sent_invitations_count_grouped_by_month, :percentage_of_no_show,
            :percentage_of_no_show_grouped_by_month, :average_time_between_invitation_and_rdv_in_days,
            :average_time_between_invitation_and_rdv_in_days_by_month,
            :average_time_between_rdv_creation_and_start_in_days,
            :average_time_between_rdv_creation_and_start_in_days_by_month,
            :rate_of_applicants_with_rdv_seen_in_less_than_30_days,
            :rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month,
            :rate_of_applicants_autonomy,
            :rate_of_applicants_autonomy_grouped_by_month,
            :agents_count, presence: true, allow_blank: true
end
