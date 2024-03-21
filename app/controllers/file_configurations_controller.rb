class FileConfigurationsController < ApplicationController
  PERMITTED_PARAMS = [
    :sheet_name, :title_column, :first_name_column, :last_name_column, :role_column, :email_column, :nir_column,
    :phone_number_column, :birth_date_column, :birth_name_column, :address_first_field_column,
    :address_second_field_column, :address_third_field_column, :address_fourth_field_column,
    :address_fifth_field_column, :department_internal_id_column, :affiliation_number_column, :tags_column,
    :rights_opening_date_column, :organisation_search_terms_column, :referent_email_column, :france_travail_id_column
  ].freeze

  before_action :set_organisation, only: [:show, :new, :create, :edit, :confirm_update, :update]
  before_action :set_file_configuration, only: [:show, :edit, :confirm_update, :update]
  before_action :set_edit_form_url, :set_edit_form_html_method, only: [:edit, :update]

  def show; end

  def new
    @file_configuration = FileConfiguration.new
  end

  def edit; end

  def confirm_update
    @file_configuration.assign_attributes(**formatted_params)
    render turbo_stream: turbo_stream.replace(
      "remote_modal", partial: "confirm_update", locals: {
        organisation: @organisation,
        current_file_configuration: @file_configuration,
        new_file_configuration: FileConfiguration.new(**formatted_params.compact_blank)
      }
    )
  end

  def create
    @file_configuration = FileConfiguration.new(**formatted_params)
    if @file_configuration.save
      flash.now[:success] = "Le fichier d'import a été créé avec succès"
    else
      render_errors("Créer fichier d'import", :post, organisation_file_configurations_path(@organisation))
    end
  end

  def update
    @file_configuration.assign_attributes(**formatted_params)
    if @file_configuration.save
      flash.now[:success] = "Le fichier d'import a été modifié avec succès"
    else
      render_errors("Modifier fichier d'import", @edit_form_html_method, @edit_form_url)
    end
  end

  private

  def file_configuration_params
    params.require(:file_configuration).permit(*PERMITTED_PARAMS).to_h.deep_symbolize_keys
  end

  def formatted_params
    # we nullify blank column names for validations to be accurate
    file_configuration_params.to_h do |k, v|
      [k, k.to_s.in?(FileConfiguration.column_attributes_names) ? v.presence : v]
    end
  end

  def render_errors(form_title, form_method, form_url)
    render turbo_stream: turbo_stream.replace(
      "remote_modal", partial: "file_configuration_form", locals: {
        organisation: @organisation,
        file_configuration: @file_configuration,
        errors: @file_configuration.errors.full_messages,
        title: form_title,
        method: form_method,
        url: form_url
      }
    )
  end

  def set_edit_form_url
    @edit_form_url =
      if @file_configuration.category_configurations.length > 1
        organisation_file_configuration_confirm_update_path(@organisation, @file_configuration)
      else
        organisation_file_configuration_path(@organisation, @file_configuration)
      end
  end

  def set_edit_form_html_method
    @edit_form_html_method =
      if @file_configuration.category_configurations.length > 1
        :get
      else
        :patch
      end
  end

  def set_organisation
    @organisation = policy_scope(Organisation).find(params[:organisation_id])
    authorize @organisation, :configure?
  end

  def set_file_configuration
    file_configuration_id = params[:file_configuration_id].presence || params[:id]
    @file_configuration = FileConfiguration.find(file_configuration_id)
  end
end
