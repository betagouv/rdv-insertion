# rubocop:disable Metrics/ClassLength

class UsersController < ApplicationController
  PERMITTED_PARAMS = [
    :uid, :role, :first_name, :last_name, :nir, :france_travail_id, :birth_date, :email, :phone_number,
    :birth_name, :address, :affiliation_number, :department_internal_id, :title,
    :status, :rights_opening_date, :created_through, :created_from_structure_type, :created_from_structure_id,
    { follow_ups_attributes: [:motif_category_id], tag_users_attributes: [:tag_id] }
  ].freeze

  include BackToListConcern
  include Users::Filterable
  include Users::Sortable
  include Users::Taggable
  include Users::Archivable

  before_action :set_organisation, :set_department, :set_all_configurations,
                :set_current_organisations, :set_users_scope,
                :set_current_category_configuration, :set_current_motif_category,
                :set_users, :set_follow_ups, :set_structure_orientations, :set_orientation_types, :set_filterable_tags,
                :set_referents_list, :filter_users, :order_users,
                for: :index
  before_action :set_user, :set_organisation, :set_department, :set_current_organisations, :set_all_configurations,
                :set_user_tags, :set_user_referents, :set_back_to_users_list_url, :set_user_archives,
                :set_user_is_archived,
                for: :show
  before_action :set_organisation, :set_department,
                for: :new
  before_action :set_organisation, :set_department,
                for: :create
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
        authorize_all @current_organisations, :export_csv
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
    @user.assign_attributes(formatted_attributes.except(*restricted_user_attributes))
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

  def restricted_user_attributes = UserPolicy.restricted_user_attributes_for(user: @user, agent: current_agent)

  def formatted_attributes
    # we nullify some blank params for unicity exceptions (ActiveRecord::RecordNotUnique) not to raise
    user_params.to_h do |k, v|
      [k, k.in?([:affiliation_number, :department_internal_id, :email, :france_travail_id, :nir]) ? v.presence : v]
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
      current_agent.id,
      request.query_parameters
    )
  end

  def set_filterable_tags
    @tags = policy_scope((@organisation || @department).tags).order(Arel.sql("LOWER(tags.value)")).group("tags.id")
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
      .preload(:tag_users)
      .where(current_organisations_filter)
      .preload(:archives)
      .find(params[:id])
  end

  def set_organisation
    @organisation =
      if department_level?
        set_organisation_at_department_level
      else
        current_organisation
      end
  end

  def set_organisation_at_department_level
    return set_organisation_through_form if params[:action] == "create"
    return if @user.nil? # no need to set an organisation if we are not in an user-level page

    @organisation = policy_scope(Organisation)
                    .find_by(id: @user.organisation_ids, department_id: params[:department_id])
  end

  def set_structure_orientations
    @structure_orientations = Orientation.active.where(organisation: @current_organisations)
  end

  def set_orientation_types
    @orientation_types = OrientationType.where(id: @structure_orientations.pluck(:orientation_type_id).uniq)
  end

  def set_user_referents
    @user_referents = policy_scope(@user.referents)
                      .joins(:departments)
                      .where(departments: { id: current_department_id })
                      .distinct
  end

  def set_organisation_through_form
    # for now we allow only one organisation through creation
    @organisation = Organisation.find_by(
      id: params[:user][:organisation_ids], department_id: params[:department_id]
    )
  end

  def set_current_organisations
    @current_organisations = department_level? ? current_agent_department_organisations : [@organisation]
  end

  def set_department
    @department = current_department
  end

  def set_all_configurations
    @all_configurations =
      policy_scope(CategoryConfiguration).preload(:motif_category)
                                         .joins(:organisation)
                                         .where(current_organisation_filter)
                                         .uniq(&:motif_category_id)

    @all_configurations.sort_by! do |c|
      department_level? ? c.department_position : c.position
    end
  end

  def set_current_category_configuration
    return if archived_scope?
    return unless params[:motif_category_id]

    @current_category_configuration =
      @all_configurations.find { |c| c.motif_category_id == params[:motif_category_id].to_i }
  end

  def set_current_motif_category
    @current_motif_category = @current_category_configuration&.motif_category
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
             .preload(:organisations).where(organisations: @current_organisations)
    return if request.format == "csv"

    @users = @users.preload(:archives, follow_ups: [:invitations])
  end

  def set_users_for_motif_category
    @users = policy_scope(User)
             .preload(:organisations, follow_ups: [:notifications, :invitations, { participations: :rdv }])
             .active.distinct
             .where(organisations: @current_organisations)
             .where.not(id: archived_user_ids_in_organisations(@current_organisations))
             .joins(:follow_ups)
             .where(follow_ups: { motif_category: @current_motif_category })
             .where.not(follow_ups: { status: "closed" })
  end

  def set_archived_users
    @users = policy_scope(User)
             .includes(:archives)
             .preload(:invitations, :participations)
             .where(id: archived_user_ids_in_organisations(@current_organisations))
             .active.distinct
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
