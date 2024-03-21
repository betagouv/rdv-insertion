class MessagesConfigurationsController < ApplicationController
  PERMITTED_PARAMS = [
    { direction_names: [] }, :sender_city, :letter_sender_name, { signature_lines: [] }, :help_address,
    :display_europe_logos, :display_france_travail_logo, :display_department_logo, :sms_sender_name
  ].freeze

  before_action :set_organisation, only: [:show, :new, :edit, :create, :update]
  before_action :set_messages_configuration, only: [:show, :edit, :update]

  def show; end

  def new
    @messages_configuration = MessagesConfiguration.new(organisation: @organisation)
  end

  def edit; end

  def create
    @messages_configuration = MessagesConfiguration.new(organisation: @organisation)
    @messages_configuration.assign_attributes(**formatted_params)
    if @messages_configuration.save
      flash.now[:success] = "Les réglages ont été modifiés avec succès"
      redirect_to organisation_category_configurations_path(@organisation)
    else
      flash.now[:error] = @messages_configuration.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @messages_configuration.assign_attributes(**formatted_params)
    if @messages_configuration.save
      flash.now[:success] = "Les réglages ont été modifiés avec succès"
      render :show
    else
      flash.now[:error] = @messages_configuration.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def messages_configuration_params
    params.require(:messages_configuration).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_params
    # we nullify some blank params
    messages_configuration_params.to_h do |k, v|
      [k, k.in?([:sms_sender_name, :letter_sender_name, :sender_city]) ? v.presence : v]
    end
  end

  def set_messages_configuration
    @messages_configuration = policy_scope(MessagesConfiguration).find(params[:id])
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
    authorize @organisation, :configure?
  end
end
