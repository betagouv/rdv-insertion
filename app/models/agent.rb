class Agent < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:email, :first_name, :last_name].freeze

  validates :email, presence: true, uniqueness: true
  validates :rdv_solidarites_agent_id, uniqueness: true, allow_nil: true

  has_many :agent_roles, dependent: :destroy
  has_many :referent_assignations, dependent: :destroy
  has_many :agents_rdvs, dependent: :destroy

  has_many :organisations, through: :agent_roles
  has_many :departments, -> { distinct }, through: :organisations
  has_many :configurations, through: :organisations
  has_many :motif_categories, -> { distinct }, through: :organisations
  has_many :rdvs, through: :agents_rdvs
  has_many :users, through: :referent_assignations

  scope :not_betagouv, -> { where.not("agents.email LIKE ?", "%beta.gouv.fr") }
  scope :super_admins, -> { where(super_admin: true) }

  def delete_organisation(organisation)
    organisations.delete(organisation)
    save!
  end

  def admin_organisations_ids
    agent_roles.select(&:admin?).map(&:organisation_id)
  end

  def to_s
    "#{first_name} #{last_name}"
  end
end
