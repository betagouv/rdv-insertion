module Users
  class BatchActionsController < ApplicationController
    include BackToListConcern
    include Users::Sortable

    before_action :set_organisation, :set_department, :set_all_configurations, :set_current_category_configuration,
                  :set_current_motif_category, :set_organisations, :set_motif_category_name, :set_users,
                  :set_rdv_contexts, :set_back_to_users_list_url, :filter_users_by_non_invited_status,
                  :order_by_rdv_contexts, for: :new

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

    def set_rdv_contexts
      @rdv_contexts = RdvContext.where(
        user_id: @users.ids, motif_category: @current_motif_category
      )
    end

    def filter_users_by_non_invited_status
      @users = @users.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.status("not_invited"))
    end

    def set_users
      @users = policy_scope(User)
               .preload({ organisations: [:motif_categories], rdv_contexts: [:participations] })
               .active.distinct
               .where(department_level? ? { organisations: @organisations } : { organisations: @organisation })
               .where.not(id: @department.archived_users.ids)
               .joins(:rdv_contexts)
               .where(rdv_contexts: { motif_category: @current_motif_category })
               .where.not(rdv_contexts: { status: "closed" })
    end
  end
end
