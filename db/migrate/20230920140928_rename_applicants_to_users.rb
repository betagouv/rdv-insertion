class RenameApplicantsToUsers < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/MethodLength
  def change
    rename_table :applicants, :users
    rename_table :applicants_organisations, :users_organisations
    rename_table :tag_applicants, :tag_users

    rename_column :users_organisations, :applicant_id, :user_id
    rename_column :archives, :applicant_id, :user_id
    rename_column :configurations, :convene_applicant, :convene_user
    rename_column :configurations, :invite_to_applicant_organisations_only, :invite_to_user_organisations_only
    rename_column :configurations, :template_applicant_designation_override, :template_user_designation_override
    rename_column :invitations, :applicant_id, :user_id
    rename_column :participations, :applicant_id, :user_id
    rename_column :follow_ups, :applicant_id, :user_id
    rename_column :referent_assignations, :applicant_id, :user_id
    rename_column :stats, :applicants_count, :users_count
    rename_column :stats, :applicants_count_grouped_by_month, :users_count_grouped_by_month
    rename_column :stats, :rate_of_applicants_with_rdv_seen_in_less_than_30_days,
                  :rate_of_users_with_rdv_seen_in_less_than_30_days
    rename_column :stats, :rate_of_applicants_with_rdv_seen_in_less_than_30_days_by_month,
                  :rate_of_users_with_rdv_seen_in_less_than_30_days_by_month
    rename_column :stats, :rate_of_autonomous_applicants, :rate_of_autonomous_users
    rename_column :stats, :rate_of_autonomous_applicants_grouped_by_month, :rate_of_autonomous_users_grouped_by_month
    rename_column :tag_users, :applicant_id, :user_id
    rename_column :templates, :applicant_designation, :user_designation
  end
  # rubocop:enable Metrics/MethodLength
end
