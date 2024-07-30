class Organisation < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:name, :phone_number, :email].freeze
  SEARCH_ATTRIBUTES = [:name, :slug].freeze

  include Searchable
  include HasLogo

  before_create { build_messages_configuration }

  validates :rdv_solidarites_organisation_id, uniqueness: true, allow_nil: true
  validates :name, :organisation_type, presence: true
  validates :email, allow_blank: true, format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/ }
  validate :validate_organisation_phone_number

  belongs_to :department
  has_one :stat, as: :statable, dependent: :destroy
  has_one :messages_configuration, dependent: :destroy
  has_many :category_configurations, dependent: :destroy
  has_many :rdvs, dependent: :nullify
  has_many :participations, through: :rdvs
  has_many :lieux, dependent: :nullify
  has_many :motifs, dependent: :nullify
  has_many :agent_roles, dependent: :destroy
  has_many :users_organisations, dependent: :destroy
  has_many :tag_organisations, dependent: :destroy
  has_many :orientations, dependent: :restrict_with_error
  has_many :csv_exports, as: :structure, dependent: :destroy
  has_many :webhook_endpoints, dependent: :destroy

  has_many :users, through: :users_organisations
  has_many :agents, through: :agent_roles
  has_many :motif_categories, -> { distinct }, through: :category_configurations
  has_many :archived_users, through: :department
  has_many :tags, through: :tag_organisations

  has_and_belongs_to_many :invitations, dependent: :nullify

  delegate :name, :name_with_region, :number, to: :department, prefix: true

  enum organisation_type: {
    conseil_departemental: "conseil_departemental",
    delegataire_rsa: "delegataire_rsa",
    france_travail: "france_travail",
    siae: "siae",
    autre: "autre"
  }

  ORGANISATION_TYPES_WITH_PARCOURS_ACCESS = %w[delegataire_rsa conseil_departemental france_travail].freeze

  def rdv_solidarites_url
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/#{rdv_solidarites_organisation_id}"
  end

  def to_s
    name
  end

  def france_travail? = safir_code?

  private

  def validate_organisation_phone_number
    return if phone_number_is_valid?

    errors.add(:phone_number, :invalid)
  end

  def phone_number_is_valid?
    # Blank, Valid Phone, 4 digits phone (organisations only)
    phone_number.blank? || Phonelib.parse(phone_number).valid? || phone_number.match(/^\d{4}$/)
  end
end
