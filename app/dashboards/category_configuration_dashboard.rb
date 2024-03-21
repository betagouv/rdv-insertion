require "administrate/base_dashboard"

class CategoryConfigurationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    convene_user: Field::Boolean,
    day_of_the_month_periodic_invites: Field::Number,
    department_position: Field::Number,
    file_configuration: Field::BelongsTo,
    invitation_formats: Field::String,
    invite_to_user_organisations_only: Field::Boolean,
    motif_category: Field::BelongsTo,
    number_of_days_before_action_required: Field::Number,
    number_of_days_between_periodic_invites: Field::Number,
    organisation: Field::BelongsTo,
    position: Field::Number,
    rdv_with_referents: Field::Boolean,
    template_rdv_purpose_override: Field::String,
    template_rdv_title_by_phone_override: Field::String,
    template_rdv_title_override: Field::String,
    template_user_designation_override: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    convene_user
    day_of_the_month_periodic_invites
    department_position
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    convene_user
    day_of_the_month_periodic_invites
    department_position
    file_configuration
    invitation_formats
    invite_to_user_organisations_only
    motif_category
    number_of_days_before_action_required
    number_of_days_between_periodic_invites
    organisation
    position
    rdv_with_referents
    template_rdv_purpose_override
    template_rdv_title_by_phone_override
    template_rdv_title_override
    template_user_designation_override
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    convene_user
    day_of_the_month_periodic_invites
    department_position
    file_configuration
    invitation_formats
    invite_to_user_organisations_only
    motif_category
    number_of_days_before_action_required
    number_of_days_between_periodic_invites
    organisation
    position
    rdv_with_referents
    template_rdv_purpose_override
    template_rdv_title_by_phone_override
    template_rdv_title_override
    template_user_designation_override
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how category_configurations are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(category_configuration)
  #   "Configuration ##{category_configuration.id}"
  # end
end
