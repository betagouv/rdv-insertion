require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    address: Field::String,
    affiliation_number: Field::String,
    archives: Field::HasMany,
    birth_date: Field::Date,
    birth_name: Field::String,
    carnet_de_bord_carnet_id: Field::String,
    category_configurations: Field::HasMany,
    created_through: Field::Select.with_options(
      searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }
    ),
    deleted_at: Field::DateTime,
    department_internal_id: Field::String,
    departments: Field::HasMany,
    email: Field::String,
    first_name: Field::String,
    invitations: Field::HasMany,
    last_name: Field::String,
    last_webhook_update_received_at: Field::DateTime,
    motif_categories: Field::HasMany,
    nir: Field::String,
    notifications: Field::HasMany,
    organisations: Field::HasMany,
    participations: Field::HasMany,
    phone_number: Field::String,
    france_travail_id: Field::String,
    rdv_contexts: Field::HasMany,
    rdv_solidarites_user_id: Field::Number,
    rdvs: Field::HasMany,
    referent_assignations: Field::HasMany,
    referents: Field::HasMany,
    rights_opening_date: Field::Date,
    role: Field::Select.with_options(
      searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }
    ),
    tag_users: Field::HasMany,
    tags: Field::HasMany,
    title: Field::Select.with_options(
      searchable: false, collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }
    ),
    uid: Field::String,
    users_organisations: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = [
    :id,
    :first_name,
    :last_name,
    :email
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = [
    :id,
    :rdv_solidarites_user_id,
    :title,
    :first_name,
    :last_name,
    :birth_name,
    :email,
    :address,
    :phone_number,
    :birth_date,
    :role,
    :affiliation_number,
    :nir,
    :department_internal_id,
    :france_travail_id,
    :rights_opening_date,
    :organisations,
    :tags,
    :created_at,
    :updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = [
    :rdv_solidarites_user_id,
    :title,
    :first_name,
    :last_name,
    :birth_name,
    :email,
    :address,
    :phone_number,
    :birth_date,
    :role,
    :affiliation_number,
    :nir,
    :department_internal_id,
    :france_travail_id,
    :rights_opening_date,
    :tags
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

  # Overwrite this method to customize how users are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(user)
    "#{user.first_name} #{user.last_name}"
  end
end
