require "administrate/base_dashboard"

class AgentDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    agent_roles: Field::HasMany,
    agents_rdvs: Field::HasMany,
    category_configurations: Field::HasMany,
    departments: Field::HasMany,
    email: Field::String,
    first_name: Field::String,
    last_sign_in_at: Field::DateTime,
    last_name: Field::String,
    last_webhook_update_received_at: Field::DateTime,
    motif_categories: Field::HasMany,
    organisations: Field::HasMany,
    rdv_solidarites_agent_id: Field::Number,
    rdvs: Field::HasMany,
    referent_assignations: Field::HasMany,
    super_admin: Field::Boolean,
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
    first_name
    last_name
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    agent_roles
    agents_rdvs
    category_configurations
    departments
    email
    first_name
    last_sign_in_at
    last_name
    last_webhook_update_received_at
    motif_categories
    organisations
    rdv_solidarites_agent_id
    rdvs
    referent_assignations
    super_admin
    users
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    agent_roles
    agents_rdvs
    category_configurations
    departments
    email
    first_name
    last_name
    last_webhook_update_received_at
    motif_categories
    organisations
    rdv_solidarites_agent_id
    rdvs
    referent_assignations
    super_admin
    users
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

  # Overwrite this method to customize how agents are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(agent)
    agent.to_s
  end
end
