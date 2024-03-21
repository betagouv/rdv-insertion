class CategoryConfigurationsController < ApplicationController
  PERMITTED_PARAMS = [
    { invitation_formats: [] }, :convene_user, :rdv_with_referents, :file_configuration_id,
    :invite_to_user_organisations_only, :number_of_days_before_action_required,
    :day_of_the_month_periodic_invites, :number_of_days_between_periodic_invites, :motif_category_id,
    :template_rdv_title_override, :template_rdv_title_by_phone_override, :template_rdv_purpose_override,
    :template_user_designation_override, :phone_number
  ].freeze

  include BackToListConcern

  before_action :set_organisation, :authorize_organisation_category_configuration,
                only: [:index, :new, :create, :show, :edit, :update, :destroy]
  before_action :set_category_configuration, :set_file_configuration, :set_template,
                only: [:show, :edit, :update, :destroy]
  before_action :set_department, :set_file_configurations, only: [:new, :create, :edit, :update]
  before_action :set_back_to_users_list_url, :set_messages_configuration, :set_category_configurations, only: [:index]

  def index
    @available_tags = (@department || @organisation.department).tags.distinct
  end

  def show; end

  def new
    @category_configuration = CategoryConfiguration.new(organisation: @organisation)
  end

  def edit; end

  def create
    @category_configuration = CategoryConfiguration.new(organisation: @organisation)
    @category_configuration.assign_attributes(**category_configuration_params.compact_blank)
    if create_configuration.success?
      flash.now[:success] = "La configuration a été créée avec succès"
      redirect_to organisation_category_configuration_path(@organisation, @category_configuration)
    else
      flash.now[:error] = create_configuration.errors.join(",")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @category_configuration.assign_attributes(**formatted_configuration_params)
    if @category_configuration.save
      flash.now[:success] = "La configuration a été modifiée avec succès"
      redirect_to organisation_category_configuration_path(@organisation, @category_configuration)
    else
      flash.now[:error] = @category_configuration.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category_configuration.destroy
    flash.now[:success] = "Le contexte a été supprimé avec succès"
  end

  private

  def category_configuration_params
    params.require(:category_configuration).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_configuration_params
    category_configuration_params.to_h do |k, v|
      [k, k.to_s.include?("override") ? v.presence : v]
    end
  end

  def create_configuration
    @create_configuration ||= CategoryConfigurations::Create.call(category_configuration: @category_configuration)
  end

  def set_category_configuration
    @category_configuration = @organisation.category_configurations.find(params[:id])
  end

  def set_category_configurations
    @category_configurations = @organisation.category_configurations.includes([:motif_category])
  end

  def set_messages_configuration
    @messages_configuration = @organisation.messages_configuration
  end

  def set_file_configuration
    @file_configuration = @category_configuration.file_configuration
  end

  def set_file_configurations
    @file_configurations = @department.file_configurations.distinct
  end

  def set_template
    @template = @category_configuration.template
  end

  def set_department
    @department = @organisation.department
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
  end

  def authorize_organisation_category_configuration
    authorize @organisation, :configure?
  end
end
