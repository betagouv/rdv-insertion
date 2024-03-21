class OrganisationsController < ApplicationController
  PERMITTED_PARAMS = [
    :name, :phone_number, :email, :slug, :independent_from_cd, :logo_filename, :rdv_solidarites_organisation_id,
    :department_id
  ].freeze

  before_action :set_organisation, :set_department, :authorize_organisation_category_configuration,
                only: [:show, :edit, :update]

  def index
    @organisations = policy_scope(Organisation).includes(:department, :category_configurations)
    @organisations_by_department = @organisations.sort_by(&:department_number).group_by(&:department)
    return unless @organisations.to_a.length == 1

    redirect_to default_list_organisation_users_path(@organisations.first)
  end

  def show; end

  def edit; end

  def update
    @organisation.assign_attributes(**organisation_params)
    authorize @organisation
    if update_organisation.success?
      render :show
    else
      flash.now[:error] = update_organisation.errors&.join(",")
      render :edit, status: :unprocessable_entity
    end
  end

  def geolocated
    @department_organisations = policy_scope(Organisation).where(department: department)
    return render_impossible_to_geolocate if retrieve_geolocalisation.failure?

    if retrieve_relevant_organisations.success?
      render json: {
        success: true,
        department_organisations: @department_organisations,
        geolocated_organisations: organisations_relevant_to_sector
      }
    else
      render json: {
        success: false,
        errors: retrieve_relevant_organisations.errors,
        department_organisations: @department_organisations
      }
    end
  end

  def search
    @department_organisations = policy_scope(Organisation).where(department: department)
    @matching_organisations = @department_organisations.search_by_text(params[:search_terms])
    render json: {
      success: true,
      matching_organisations: @matching_organisations,
      department_organisations: @department_organisations
    }
  end

  private

  def organisation_params
    params.require(:organisation).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:id])
  end

  def set_department
    @department = @organisation.department
  end

  def department
    @department ||= Department.find_by!(number: params[:department_number])
  end

  def retrieve_geolocalisation
    @retrieve_geolocalisation ||= RetrieveGeolocalisation.call(
      address: params[:address],
      department_number: department.number
    )
  end

  def render_impossible_to_geolocate
    render json: {
      success: false,
      department_organisations: @department_organisations,
      errors: ["Impossible de géolocaliser le bénéficiaire à partir de l'adresse donnée"]
    }
  end

  def retrieve_relevant_organisations
    @retrieve_relevant_organisations ||=
      RdvSolidaritesApi::RetrieveOrganisations.call(
        geo_attributes: {
          departement_number: department.number,
          city_code: retrieve_geolocalisation.city_code,
          street_ban_id: retrieve_geolocalisation.street_ban_id
        }
      )
  end

  def retrieved_rdv_solidarites_organisations
    retrieve_relevant_organisations.organisations
  end

  def organisations_relevant_to_sector
    @department_organisations.select do |org|
      org.rdv_solidarites_organisation_id.in?(retrieved_rdv_solidarites_organisations.map(&:id))
    end
  end

  def update_organisation
    @update_organisation ||= Organisations::Update.call(organisation: @organisation)
  end

  def authorize_organisation_category_configuration
    authorize @organisation, :configure?
  end
end
