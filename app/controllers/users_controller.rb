# rubocop:disable Metrics/ClassLength

class UsersController < ApplicationController
  PERMITTED_PARAMS = [
    :uid, :role, :first_name, :last_name, :nir, :france_travail_id, :birth_date, :email, :phone_number,
    :birth_name, :address, :affiliation_number, :department_internal_id, :title,
    :status, :rights_opening_date,
    { follow_ups_attributes: [:motif_category_id], tag_users_attributes: [:tag_id] }
  ].freeze

  include BackToListConcern
  include Users::Filterable
  include Users::Sortable

  before_action :set_organisation, :set_department, :set_organisations, :set_all_configurations,
                :set_current_agent_roles, :set_users_scope,
                :set_current_configuration, :set_current_motif_category,
                :set_users, :set_follow_ups, :set_filterable_tags, :set_referents_list,
                :filter_users, :order_users,
                for: :index
  before_action :set_user, :set_organisation, :set_department, :set_all_configurations,
                :set_user_archive, :set_user_tags, :set_back_to_users_list_url,
                for: :show
  before_action :set_organisation, :set_department, :set_organisations,
                for: [:new, :create]
  before_action :set_user, :set_organisation, :set_department,
                for: [:edit, :update]
  before_action :reset_tag_users, only: :update
  after_action :store_back_to_users_list_url, only: [:index]

  def default_list
    redirect_to default_list_path
  end

  def index
    respond_to do |format|
      format.html
      format.csv do
        generate_csv
        flash[:success] = "Le fichier CSV est en train d'être généré." \
                          " Il sera envoyé à l'adresse email #{current_agent.email}." \
                          " Pensez à vérifier vos spams."
        redirect_to url_for(request.query_parameters.except(:format, :export_type))
      end
    end
  end

  def show; end

  def new
    @user = User.new
    authorize @user
  end

  def edit
    authorize @user
  end

  def create
    @user = upsert_user.user
    if upsert_user.success?
      render_save_user_success
    else
      render_errors(upsert_user.errors)
    end
  end

  def update
    @user.assign_attributes(**formatted_attributes)
    authorize @user
    if save_user.success?
      render_save_user_success
    else
      render_errors(save_user.errors)
    end
  end

  private

  def user_params
    params.require(:user).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_attributes
    # we nullify some blank params for unicity exceptions (ActiveRecord::RecordNotUnique) not to raise
    user_params.to_h do |k, v|
      [k, k.in?([:affiliation_number, :department_internal_id, :email, :france_travail_id, :nir]) ? v.presence : v]
    end
  end

  def reset_tag_users
    return unless user_params[:tag_users_attributes]

    @user
      .tags
      .joins(:organisations)
      .where(organisations: department_level? ? @department.organisations : @organisation)
      .find_each do |tag|
      @user.tags.delete(tag)
    end
  end

  def csv_exporter
    if params[:export_type] == "participations"
      Exporters::CreateUsersParticipationsCsvExportJob
    else
      Exporters::CreateUsersCsvExportJob
    end
  end

  def generate_csv
    csv_exporter.perform_async(
      @users.map(&:id),
      department_level? ? "Department" : "Organisation",
      department_level? ? @department.id : @organisation.id,
      @current_motif_category&.id,
      current_agent.id
    )
  end

  def render_errors(errors)
    respond_to do |format|
      format.turbo_stream { turbo_stream_replace_flash_message(error: errors.join(", ")) }
      format.html do
        flash.now[:error] = errors.join(",")
        render(action_name == "update" ? :edit : :new, status: :unprocessable_entity)
      end
      format.json { render json: { success: false, errors: errors }, status: :unprocessable_entity }
    end
  end

  def render_save_user_success
    respond_to do |format|
      format.html { redirect_to(after_save_path) }
      format.json { render json: { success: true, user: @user } }
    end
  end

  def save_user
    @save_user ||= Users::Save.call(
      user: @user,
      organisation: @organisation
    )
  end

  def upsert_user
    @upsert_user ||= Users::Upsert.call(
      user_attributes: user_params,
      organisation: @organisation
    )
  end

  def set_user
    @user =
      policy_scope(User)
      .where(current_organisations_filter)
      .find(params[:id])
  end

  def set_organisation
    @organisation =
      if department_level?
        set_organisation_at_department_level
      else
        policy_scope(Organisation).find(params[:organisation_id])
      end
  end

  def set_organisation_at_department_level
    return set_organisation_through_form if params[:action] == "create"
    return if @user.nil? # no need to set an organisation if we are not in an user-level page

    @organisation = policy_scope(Organisation)
                    .find_by(id: @user.organisation_ids, department_id: params[:department_id])
  end

  def set_filterable_tags
    @tags = policy_scope((@organisation || @department).tags).order(:value).distinct
  end

  def set_user_tags
    @tags = policy_scope(@user.tags)
            .joins(:organisations)
            .where(organisations: department_level? ? @department.organisations : @organisation)
            .order(:value)
            .distinct
  end

  def set_organisation_through_form
    # for now we allow only one organisation through creation
    @organisation = Organisation.find_by(
      id: params[:user][:organisation_ids], department_id: params[:department_id]
    )
  end

  def set_organisations
    @organisations = policy_scope(Organisation).where(department: @department)
  end

  def set_department
    @department = policy_scope(Department).find(current_department_id)
  end

  def set_all_configurations
    @all_configurations =
      policy_scope(::Configuration).joins(:organisation)
                                   .includes(:motif_category)
                                   .where(current_organisation_filter)
                                   .uniq(&:motif_category_id)
    @all_configurations.sort_by! { |c| department_level? ? c.department_position : c.position }
  end

  def set_current_configuration
    return if archived_scope?
    return unless params[:motif_category_id]

    @current_configuration =
      @all_configurations.find { |c| c.motif_category_id == params[:motif_category_id].to_i }
  end

  def set_current_motif_category
    @current_motif_category = @current_configuration&.motif_category
  end

  def set_user_archive
    @archive = Archive.find_by(user: @user, department: @department)
  end

  def set_users
    if archived_scope?
      set_archived_users
    elsif @current_motif_category
      set_users_for_motif_category
    else
      set_all_users
    end
  end

  def set_all_users
    @users = policy_scope(User)
             .active.distinct
             .where(department_level? ? { organisations: @organisations } : { organisations: @organisation })
    return if request.format == "csv"

    @users = @users.preload(:archives, follow_ups: [:invitations])
  end

  def set_users_for_motif_category
    @users = policy_scope(User)
             .preload(:organisations, follow_ups: [:notifications, :invitations])
             .active.distinct
             .where(department_level? ? { organisations: @organisations } : { organisations: @organisation })
             .where.not(id: @department.archived_users.ids)
             .joins(:follow_ups)
             .where(follow_ups: { motif_category: @current_motif_category })
             .where.not(follow_ups: { status: "closed" })
  end

  def set_archived_users
    @users = policy_scope(User)
             .includes(:archives)
             .preload(:invitations, :participations)
             .active.distinct
             .where(id: @department.archived_users)
             .where(department_level? ? { organisations: @organisations } : { organisations: @organisation })
  end

  def set_follow_ups
    return if archived_scope?

    @follow_ups = FollowUp.where(
      user_id: @users.ids, motif_category: @current_motif_category
    )
    @statuses_count = @follow_ups.group(:status).count
  end

  def set_referents_list
    @referents_list = current_structure.agents.where.not(last_name: nil).distinct.order(:last_name)
    @referents_list = @referents_list.where(super_admin: false) if production_env?
  end

  def set_current_agent_roles
    @current_agent_roles = AgentRole.where(
      department_level? ? { organisation: @organisations } : { organisation: @organisation }, agent: current_agent
    )
  end

  def set_users_scope
    @users_scope = params[:users_scope]
  end

  def archived_scope?
    @users_scope == "archived"
  end

  def after_save_path
    return department_user_path(@department, @user) if department_level?

    organisation_user_path(@organisation, @user)
  end

  def default_list_path
    motif_category_param =
      if current_structure.motif_categories.length == 1
        { motif_category_id: current_structure.motif_categories.first.id }
      else
        {}
      end
    structure_users_path(**motif_category_param)
  end
end

# rubocop: enable Metrics/ClassLength
