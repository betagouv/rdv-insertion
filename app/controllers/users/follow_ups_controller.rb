module Users
  class FollowUpsController < ApplicationController
    before_action :set_user, :set_department, :set_organisation, :set_user_department_organisations,
                  :set_all_configurations, :set_user_tags, :set_current_organisations, :set_user_archives,
                  :set_user_is_archived, :set_back_to_users_list_url, only: [:index]

    include BackToListConcern
    include Users::Taggable
    include Users::Archivable

    def index
      @follow_ups =
        FollowUp.preload(
          :invitations, participations: [:notifications, { rdv: [:motif, :organisation] }]
        ).where(
          user: @user, motif_category: @all_configurations.map(&:motif_category)
        ).sort_by do |follow_up|
          @all_configurations.find_index do |c|
            c.motif_category_id == follow_up.motif_category_id
          end
        end
    end

    private

    def set_user
      @user = policy_scope(User).preload(
        organisations: [:department, :motif_categories], follow_ups: :participations,
        tags: :tag_organisations, invitations: :follow_up
      ).find(params[:user_id])
    end

    def set_department
      @department = policy_scope(Department).preload(organisations: [:motif_categories, :motifs, :lieux])
                                            .find(current_department_id)
    end

    def set_organisation
      return if department_level?

      @organisation = policy_scope(Organisation).includes(:department, :motif_categories)
                                                .find_by(id: current_organisation_ids & @user.organisation_ids)
    end

    def set_all_configurations
      @all_configurations =
        policy_scope(CategoryConfiguration)
        .joins(:organisation)
        .where(current_organisation_filter)
        .where({ organisation: @user.department_organisations(@department).map(&:id) })
        .preload(:motif_category)
        .uniq(&:motif_category_id)

      @all_configurations =
        department_level? ? @all_configurations.sort_by(&:department_position) : @all_configurations.sort_by(&:position)
    end

    def set_user_department_organisations
      @user_department_organisations =
        policy_scope(Organisation).where(id: @user.organisation_ids, department: @department)
    end

    def set_user_archives
      @user_archives = @user.archives
    end

    def set_user_is_archived
      @user_is_archived =
        @user.archives.where(organisation: user_agent_department_organisations).count ==
        user_agent_department_organisations.count
    end

    def user_agent_department_organisations
      @user_agent_department_organisations ||= @user.organisations & @current_organisations
    end

    def set_current_organisations
      @current_organisations = department_level? ? current_agent_department_organisations : [@organisation]
    end
  end
end
