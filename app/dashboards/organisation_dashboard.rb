require "administrate/base_dashboard"

class OrganisationDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    agent_roles: Field::HasMany,
    agents: Field::HasMany,
    category_configurations: Field::HasMany,
    department: Field::BelongsTo,
    email: Field::String,
    organisation_type: Field::Select.with_options(
      searchable: false,
      collection: lambda { |field|
        field.resource.class.send(field.attribute.to_s.pluralize).keys.map do |key|
          [I18n.t("activerecord.attributes.organisation.organisation_types.#{key}"), key]
        end
      }
    ),
    safir_code: Field::String,
    invitations: Field::HasMany,
    last_webhook_update_received_at: Field::DateTime,
    lieux: Field::HasMany,
    logo: Field::ActiveStorage.with_options(show_preview_variant: false),
    logo_filename: Field::String,
    messages_configuration: Field::HasOne,
    motif_categories: Field::HasMany,
    motifs: Field::HasMany,
    name: Field::String,
    participations: Field::HasMany,
    phone_number: Field::String,
    rdv_solidarites_organisation_id: Field::Number,
    rdvs: Field::HasMany,
    slug: Field::String,
    stat: Field::HasOne,
    tag_organisations: Field::HasMany,
    tags: Field::HasMany,
    users: Field::HasMany,
    users_organisations: Field::HasMany,
    webhook_endpoints: Field::HasMany,
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
    name
    department
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    rdv_solidarites_organisation_id
    name
    phone_number
    slug
    department
    email
    organisation_type
    safir_code
    agent_roles
    lieux
    motif_categories
    created_at
    updated_at
    last_webhook_update_received_at
    logo
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    rdv_solidarites_organisation_id
    name
    phone_number
    slug
    department
    email
    organisation_type
    safir_code
    logo
  ].freeze

  FORM_ATTRIBUTES_NEW = %i[
    rdv_solidarites_organisation_id
    department
    organisation_type
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

  # Overwrite this method to customize how organisations are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(organisation)
    "#{organisation.name} (#{organisation.department.name})"
  end
end
