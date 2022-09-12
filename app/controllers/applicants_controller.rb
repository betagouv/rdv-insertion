# rubocop:disable Metrics/ClassLength

class ApplicantsController < ApplicationController
  PERMITTED_PARAMS = [
    :uid, :role, :first_name, :last_name, :birth_date, :email, :phone_number,
    :birth_name, :address, :affiliation_number, :department_internal_id, :title,
    :status, :rights_opening_date, :archiving_reason, :is_archived
  ].freeze
  before_action :set_applicant, only: [:show, :update, :edit]
  before_action :set_organisation, :set_department, :set_all_configurations, :set_current_configuration,
                :set_current_motif_category, only: [:index, :new, :create, :show, :update, :edit]
  before_action :set_organisations, only: [:new, :create]
  before_action :set_can_be_added_to_other_org, only: [:show]
  before_action :retrieve_applicants, only: [:search]
  before_action :set_applicants, :set_rdv_contexts, only: [:index]

  include FilterableApplicantsConcern
  include ApplicantsVariablesConcern
  include ExportApplicantsToCsvConcern

  def new
    @applicant = Applicant.new(department: @department)
    authorize @applicant
  end

  def create
    @applicant = find_or_initialize_applicant.applicant
    # TODO: if an applicant exists, return it to the agent to let him decide what to do
    @applicant.assign_attributes(
      department: @department,
      **applicant_params.compact_blank
    )
    authorize @applicant
    respond_to do |format|
      format.html { save_applicant_and_redirect(:new) }
      format.json { save_applicant_and_render }
    end
  end

  def index
    filter_applicants
    @applicants = @applicants.order(created_at: :desc)
    respond_to do |format|
      format.html
      format.csv { export_applicants_to_csv }
    end
  end

  def show
    authorize @applicant
  end

  def search
    render json: { success: true, applicants: @applicants }
  end

  def edit
    authorize @applicant
  end

  def update
    @applicant.assign_attributes(**formatted_params)
    authorize @applicant
    respond_to do |format|
      format.html { save_applicant_and_redirect(:edit) }
      format.json { save_applicant_and_render }
    end
  end

  private

  def applicant_params
    params.require(:applicant).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_params
    # we nullify some blank params for unicity exceptions (ActiveRecord::RecordNotUnique) not to raise
    applicant_params.to_h do |k, v|
      [k, k.in?([:affiliation_number, :department_internal_id, :email]) ? v.presence : v]
    end
  end

  def find_or_initialize_applicant
    @find_or_initialize_applicant ||= FindOrInitializeApplicant.call(
      department_internal_id: applicant_params[:department_internal_id],
      role: applicant_params[:role],
      affiliation_number: applicant_params[:affiliation_number],
      department_id: @department.id
    )
  end

  def save_applicant_and_redirect(page)
    if save_applicant.success?
      redirect_to(after_save_path)
    else
      flash.now[:error] = save_applicant.errors&.join(',')
      render page, status: :unprocessable_entity
    end
  end

  def save_applicant_and_render
    if save_applicant.success?
      render json: { success: true, applicant: @applicant }
    else
      render json: { success: false, errors: save_applicant.errors }, status: :unprocessable_entity
    end
  end

  def save_applicant
    @save_applicant ||= SaveApplicant.call(
      applicant: @applicant,
      organisation: @organisation,
      rdv_solidarites_session: rdv_solidarites_session
    )
  end

  def set_applicant
    @applicant = \
      Applicant
      .includes(:organisations, rdv_contexts: [{ rdvs: [:organisation] }, :invitations], invitations: [:rdv_context])
      .find(params[:id])
  end

  def set_organisations
    return unless department_level?

    @organisations = policy_scope(Organisation).where(department: @department)
  end

  def set_current_configuration
    @current_configuration = \
      @all_configurations.find { |c| c.motif_category == params[:motif_category] } || @all_configurations.first
  end

  def set_current_motif_category
    @current_motif_category = @current_configuration&.motif_category
  end

  def set_can_be_added_to_other_org
    @can_be_added_to_other_org = (@department.organisation_ids - @applicant.organisation_ids).any?
  end

  def set_applicants
    @applicants = policy_scope(Applicant)
                  .includes(:invitations)
                  .preload(:organisations, rdv_contexts: [:invitations, :rdvs])
                  .archived(false)
                  .joins(:rdv_contexts)
                  .where(rdv_contexts: { motif_category: @current_motif_category })
                  .active.distinct
    @applicants = \
      if department_level?
        @applicants.where(department: @department)
      else
        @applicants.where(organisations: @organisation)
      end
  end

  def set_rdv_contexts
    @rdv_contexts = RdvContext.where(applicant_id: @applicants.ids, motif_category: @current_motif_category)
    @statuses_count = @rdv_contexts.group(:status).count
  end

  def after_save_path
    return department_applicant_path(@department, @applicant) if department_level?

    organisation_applicant_path(@organisation, @applicant)
  end

  def retrieve_applicants
    @applicants = policy_scope(Applicant).includes(:organisations, :rdvs, invitations: [:rdv_context]).distinct
    @applicants = @applicants
                  .where(department_internal_id: params.require(:applicants)[:department_internal_ids])
                  .or(@applicants.where(uid: params.require(:applicants)[:uids]))
                  .to_a
  end
end

# rubocop: enable Metrics/ClassLength
