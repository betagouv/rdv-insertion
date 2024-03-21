class ConfigurationsController < ApplicationController
  PERMITTED_PARAMS = [
    { invitation_formats: [] }, :convene_user, :rdv_with_referents, :file_configuration_id,
    :invite_to_user_organisations_only, :number_of_days_before_action_required,
    :day_of_the_month_periodic_invites, :number_of_days_between_periodic_invites, :motif_category_id,
    :template_rdv_title_override, :template_rdv_title_by_phone_override, :template_rdv_purpose_override,
    :template_user_designation_override, :phone_number
  ].freeze

  include BackToListConcern

  before_action :set_organisation, :authorize_organisation_configuration,
                only: [:index, :new, :create, :show, :edit, :update, :destroy]
  before_action :set_configuration, :set_file_configuration, :set_template, only: [:show, :edit, :update, :destroy]
  before_action :set_department, :set_file_configurations, only: [:new, :create, :edit, :update]
  before_action :set_back_to_users_list_url, :set_messages_configuration, :set_configurations, only: [:index]

  def index
    @available_tags = (@department || @organisation.department).tags.distinct
  end

  def show; end

  def new
    @configuration = ::Configuration.new(organisation: @organisation)
  end

  def edit; end

  def create
    @configuration = ::Configuration.new(organisation: @organisation)
    @configuration.assign_attributes(**configuration_params.compact_blank)
    if create_configuration.success?
      flash.now[:success] = "La configuration a été créée avec succès"
      redirect_to organisation_configuration_path(@organisation, @configuration)
    else
      flash.now[:error] = create_configuration.errors.join(",")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @configuration.assign_attributes(**formatted_configuration_params)
    if @configuration.save
      flash.now[:success] = "La configuration a été modifiée avec succès"
      redirect_to organisation_configuration_path(@organisation, @configuration)
    else
      flash.now[:error] = @configuration.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @configuration.destroy!
    flash.now[:success] = "La configuration a été supprimée avec succès"
  end

  private

  def configuration_params
    params.require(:configuration).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_configuration_params
    configuration_params.to_h do |k, v|
      [k, k.to_s.include?("override") ? v.presence : v]
    end
  end

  def create_configuration
    @create_configuration ||= Configurations::Create.call(configuration: @configuration)
  end

  def set_configuration
    @configuration = @organisation.configurations.find(params[:id])
  end

  def set_configurations
    @configurations = @organisation.configurations.includes([:motif_category])
  end

  def set_messages_configuration
    @messages_configuration = @organisation.messages_configuration
  end

  def set_file_configuration
    @file_configuration = @configuration.file_configuration
  end

  def set_file_configurations
    @file_configurations = @department.file_configurations.distinct
  end

  def set_template
    @template = @configuration.template
  end

  def set_department
    @department = @organisation.department
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
  end

  def authorize_organisation_configuration
    authorize @organisation, :configure?
  end
end
