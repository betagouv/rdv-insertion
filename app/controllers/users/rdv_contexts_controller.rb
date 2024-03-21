module Users
  class RdvContextsController < ApplicationController
    before_action :set_user, :set_department, :set_organisation, :set_user_organisations, :set_all_configurations,
                  :set_back_to_users_list_url, only: [:index]

    include BackToListConcern

    def index
      @rdv_contexts =
        RdvContext.preload(
          :invitations, participations: [:notifications, { rdv: [:motif, :organisation] }]
        ).where(
          user: @user, motif_category: @all_configurations.map(&:motif_category)
        ).sort_by do |rdv_context|
          @all_configurations.find_index do |c|
            c.motif_category_id == rdv_context.motif_category_id
          end
        end
    end

    private

    def set_user
      @user = policy_scope(User).preload(
        organisations: [:department, :motif_categories], rdv_contexts: :participations,
        tags: :tag_organisations, invitations: :rdv_context
      ).find(params[:user_id])
    end

    def set_department
      @department = policy_scope(Department).preload(organisations: [:motif_categories, :motifs, :lieux])
                                            .find(current_department_id)
    end

    def set_organisation
      # needed for now even if department level to retrieve the help_phone_number and to compute the invitation path in
      # the InvitationBlock react component
      @organisation = policy_scope(Organisation).includes(:department, :motif_categories)
                                                .find_by(id: current_organisation_ids & @user.organisation_ids)
    end

    def set_all_configurations
      @all_configurations =
        policy_scope(CategoryConfiguration).joins(:organisation)
                                           .where(current_organisation_filter)
                                           .where({ organisation: @user_organisations.map(&:id) })
                                           .preload(:motif_category)
                                           .uniq(&:motif_category_id)

      @all_configurations =
        department_level? ? @all_configurations.sort_by(&:department_position) : @all_configurations.sort_by(&:position)
    end

    def set_user_organisations
      @user_organisations =
        policy_scope(Organisation).where(id: @user.organisation_ids, department: @department)
    end
  end
end
