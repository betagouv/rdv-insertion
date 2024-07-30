module Users
  class BatchActionsController < ApplicationController
    include BackToListConcern
    include Users::Sortable
    include Users::Archivable

    before_action :set_organisation, :set_department, :set_all_configurations, :set_current_category_configuration,
                  :set_current_motif_category, :set_organisations, :set_motif_category_name, :set_current_organisations,
                  :set_users, :set_follow_ups, :set_back_to_users_list_url, :filter_users_by_non_invited_status,
                  :order_by_follow_ups, only: :new

    def new; end

    private

    def set_organisation
      return if department_level?

      @organisation =
        Organisation.preload(department: { organisations: [:motif_categories, :motifs, :lieux] })
                    .find(params[:organisation_id])
      authorize @organisation, :batch_actions?
    end

    def set_department
      @department =
        if department_level?
          Department.preload(organisations: [:motif_categories, :motifs, :lieux]).find(params[:department_id])
        else
          @organisation.department
        end
      authorize @department, :batch_actions? if department_level?
    end

    def set_organisations
      @organisations = policy_scope(Organisation)
                       .where(department: @department)
                       .where(category_configurations:
                       @all_configurations.where(
                         motif_category: @current_motif_category
                       ))
    end

    def set_all_configurations
      @all_configurations =
        policy_scope(CategoryConfiguration).joins(:organisation)
                                           .where(current_organisation_filter)
    end

    def set_current_category_configuration
      return unless params[:motif_category_id]

      @current_category_configuration =
        @all_configurations.find { |c| c.motif_category_id == params[:motif_category_id].to_i }
    end

    def set_motif_category_name
      @motif_category_name = @current_category_configuration&.motif_category_name
    end

    def set_current_motif_category
      @current_motif_category = @current_category_configuration&.motif_category
    end

    def set_follow_ups
      @follow_ups = FollowUp.where(
        user_id: @users.ids, motif_category: @current_motif_category
      )
    end

    def filter_users_by_non_invited_status
      @users = @users.joins(:follow_ups).where(follow_ups: @follow_ups.status("not_invited"))
    end

    def set_users
      @users = policy_scope(User)
               .preload({ organisations: [:motif_categories], follow_ups: [:participations] })
               .active.distinct
               .where(department_level? ? { organisations: @organisations } : { organisations: @organisation })
               .where.not(id: archived_user_ids_in_organisations(@current_organisations))
               .joins(:follow_ups)
               .where(follow_ups: { motif_category: @current_motif_category })
               .where.not(follow_ups: { status: "closed" })
    end

    def set_current_organisations
      @current_organisations = department_level? ? @organisations : [@organisation]
    end
  end
end
