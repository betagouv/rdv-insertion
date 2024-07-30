require "administrate/base_dashboard"

class DepartmentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    agents: Field::HasMany,
    capital: Field::String,
    carnet_de_bord_deploiement_id: Field::String,
    category_configurations: Field::HasMany,
    display_in_stats: Field::Boolean,
    email: Field::String,
    file_configurations: Field::HasMany,
    invitations: Field::HasMany,
    logo: Field::ActiveStorage.with_options(show_preview_variant: false),
    motif_categories: Field::HasMany,
    name: Field::String,
    number: Field::String,
    organisations: Field::HasMany,
    orientation_types: Field::HasMany,
    participations: Field::HasMany,
    phone_number: Field::String,
    pronoun: Field::String,
    follow_ups: Field::HasMany,
    rdvs: Field::HasMany,
    region: Field::String,
    stat: Field::HasOne,
    tags: Field::HasMany,
    users: Field::HasMany,
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
    number
    name
    organisations
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    pronoun
    name
    capital
    number
    region
    email
    phone_number
    carnet_de_bord_deploiement_id
    display_in_stats
    organisations
    orientation_types
    created_at
    updated_at
    logo
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    pronoun
    name
    capital
    number
    region
    email
    phone_number
    carnet_de_bord_deploiement_id
    display_in_stats
    logo
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

  # Overwrite this method to customize how departments are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(department)
    department.name
  end
end
