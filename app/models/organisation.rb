class Organisation < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:name, :phone_number, :email].freeze
  SEARCH_ATTRIBUTES = [:name, :slug].freeze

  include Searchable
  include HasLogo

  validates :rdv_solidarites_organisation_id, uniqueness: true, allow_nil: true
  validates :name, presence: true
  validates :email, allow_blank: true, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ }
  validate :validate_organisation_phone_number

  belongs_to :department
  has_one :messages_configuration, dependent: :destroy
  has_many :configurations, dependent: :destroy
  has_many :rdvs, dependent: :nullify
  has_many :lieux, dependent: :nullify
  has_many :motifs, dependent: :nullify
  has_many :agent_roles, dependent: :destroy
  has_many :agents, through: :agent_roles
  has_many :motif_categories, -> { distinct }, through: :configurations
  has_many :tag_organisations, dependent: :destroy

  has_many :tags, through: :tag_organisations

  has_and_belongs_to_many :applicants, dependent: :nullify
  has_and_belongs_to_many :invitations, dependent: :nullify
  has_and_belongs_to_many :webhook_endpoints

  delegate :name, :name_with_region, :number, to: :department, prefix: true

  def rdv_solidarites_url
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/#{rdv_solidarites_organisation_id}"
  end

  def to_s
    name
  end

  def as_json(...)
    super.deep_symbolize_keys
         .except(:last_webhook_update_received_at, :rdv_solidarites_organisation_id)
         .merge(department_number: department_number, motif_categories: motif_categories)
  end

  def validate_organisation_phone_number
    return if phone_number_is_valid?

    errors.add(:phone_number, :invalid)
  end

  def phone_number_is_valid?
    # Blank, Valid Phone, 4 digits phone (organisations only)
    phone_number.blank? || Phonelib.parse(phone_number).valid? || phone_number.match(/^\d{4}$/)
  end
end
