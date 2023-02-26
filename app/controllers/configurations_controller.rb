class ConfigurationsController < ApplicationController
  PERMITTED_PARAMS = [
    { invitation_formats: [] }, :number_of_days_to_accept_invitation, :convene_applicant, :rdv_with_referents,
    :invite_to_applicant_organisations_only, :number_of_days_before_action_required, :motif_category_id,
    :file_configuration_id
  ].freeze

  include BackToListConcern

  before_action :set_organisation, :authorize_organisation,
                only: [:index, :new, :create, :show, :edit, :update, :destroy]
  before_action :set_configuration, :set_file_configuration, only: [:show, :edit, :update, :destroy]
  before_action :set_department, only: [:new, :create, :edit, :update]
  before_action :set_back_to_applicants_list_url, :set_messages_configuration, :set_configurations, only: [:index]

  def index; end

  def show; end

  def new
    @configuration = ::Configuration.new(organisations: [@organisation])
  end

  def edit; end

  def create
    @configuration = ::Configuration.new(organisations: [@organisation])
    @configuration.assign_attributes(**configuration_params.compact_blank)
    if @configuration.save
      redirect_to organisation_configuration_path(@organisation, @configuration)
    else
      flash.now[:error] = @configuration.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @configuration.assign_attributes(**configuration_params)
    if @configuration.save
      redirect_to organisation_configuration_path(@organisation, @configuration)
    else
      flash.now[:error] = @configuration.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @configuration.organisations.delete(@organisation)
    @configuration.destroy if @configuration.organisations.blank?
    flash.now[:success] = "Le contexte a été supprimé avec succès"
  end

  private

  def configuration_params
    params.require(:configuration).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def set_configuration
    @configuration = OrganisationConfigurationPolicy::Scope.new(current_agent, ::Configuration)
                                                           .resolve
                                                           .find(params[:id])
  end

  def set_configurations
    @configurations = OrganisationConfigurationPolicy::Scope.new(current_agent, ::Configuration)
                                                            .resolve
                                                            .where(organisations: @organisation)
                                                            .includes([:motif_category])
  end

  def set_messages_configuration
    @messages_configuration = @organisation.messages_configuration
  end

  def set_file_configuration
    @file_configuration = @configuration.file_configuration
  end

  def set_department
    @department = @organisation.department
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
  end

  def authorize_organisation
    authorize @organisation, policy_class: OrganisationConfigurationPolicy
  end
end
