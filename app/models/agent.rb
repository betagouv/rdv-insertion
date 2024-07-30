class Agent < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:email, :first_name, :last_name, :inclusion_connect_open_id_sub].freeze

  include Agent::RdvSolidaritesClient
  include Agent::Signature

  has_many :agent_roles, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy
  has_many :orientations, dependent: :nullify
  has_many :csv_exports, dependent: :destroy

  has_many :organisations, through: :agent_roles
  has_many :departments, -> { distinct }, through: :organisations
  has_many :category_configurations, through: :organisations
  has_many :motif_categories, -> { distinct }, through: :organisations
  has_many :rdvs, through: :agents_rdvs
  has_many :users, through: :referent_assignations

  validates :email, presence: true, uniqueness: true
  validates :inclusion_connect_open_id_sub, uniqueness: true, allow_nil: true
  validates :rdv_solidarites_agent_id, uniqueness: true, allow_nil: true

  validate :cannot_save_as_super_admin

  scope :not_betagouv, -> { where.not("agents.email LIKE ?", "%beta.gouv.fr") }
  scope :super_admins, -> { where(super_admin: true) }
  scope :with_last_name, -> { where.not(last_name: nil) }

  def delete_organisation(organisation)
    organisations.delete(organisation)
    save!
  end

  def admin_organisations_ids
    agent_roles.select(&:admin?).map(&:organisation_id)
  end

  def export_organisations_ids
    agent_roles.select(&:authorized_to_export_csv?).map(&:organisation_id)
  end

  def to_s
    "#{first_name} #{last_name&.upcase}".strip
  end

  def department_organisations(department_id)
    organisations.select { |organisation| organisation.department_id == department_id }
  end

  private

  # This is to make sure an agent can't be set as super_admin through an agent creation or update in the app.
  # To set an agent as superadmin a developer should use agent#update_column.
  def cannot_save_as_super_admin
    return unless super_admin_changed? && super_admin == true

    errors.add(:super_admin, "ne peut pas être mis à jour")
  end
end
