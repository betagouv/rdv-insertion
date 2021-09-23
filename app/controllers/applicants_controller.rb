class ApplicantsController < ApplicationController
  PERMITTED_PARAMS = [
    :uid, :role, :first_name, :last_name, :birth_date, :email, :phone_number,
    :birth_name, :address, :affiliation_number, :custom_id, :title
  ].freeze
  before_action :retrieve_applicants, only: [:search]
  before_action :set_department, only: [:index, :create]

  def index
    @applicants = @department.applicants
    @applicants = @applicants.search_by_text(params[:search_query]) if params[:search_query].present?
    @applicants = @applicants.page(page)
    authorize_applicants
    # temporary solution to have up to date applicants with RDVS
    refresh_applicants
  end

  def search
    authorize_applicants
    # temporary solution to have up to date applicants with RDVS
    refresh_applicants
    render json: {
      success: true,
      applicants: @applicants,
      next_page: refresh_applicants.next_page
    }
  end

  def create
    authorize @department, :create_applicant?
    if create_applicant.success?
      render json: { success: true, applicant: create_applicant.applicant }
    else
      render json: { success: false, errors: create_applicant.errors }
    end
  end

  private

  def applicant_params
    params.require(:applicant).permit(*PERMITTED_PARAMS)
  end

  def create_applicant
    @create_applicant ||= CreateApplicant.call(
      applicant_data: applicant_params.to_h.deep_symbolize_keys,
      rdv_solidarites_session: rdv_solidarites_session,
      department: @department
    )
  end

  def refresh_applicants
    @refresh_applicants ||= RefreshApplicants.call(
      applicants: @applicants,
      rdv_solidarites_session: rdv_solidarites_session,
      rdv_solidarites_page: params[:rdv_solidarites_page]
    )
  end

  def authorize_applicants
    @applicants.each { |a| authorize a }
  end

  def retrieve_applicants
    @applicants = Applicant.includes(:department, :invitations)
                           .where(uid: params.require(:applicants).require(:uids))
                           .to_a
  end

  def set_department
    @department = Department.find(params[:department_id])
  end
end
