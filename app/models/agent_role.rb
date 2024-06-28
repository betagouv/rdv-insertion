class AgentRole < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:access_level].freeze

  belongs_to :agent
  belongs_to :organisation

  validates :rdv_solidarites_agent_role_id, uniqueness: true, allow_nil: true
  validates :agent, uniqueness: { scope: :organisation, message: "est déjà relié à l'organisation" }

  enum access_level: { basic: "basic", admin: "admin" }

  scope :authorized_to_export_csv, -> { where(authorized_to_export_csv: true) }
  scope :with_last_name, -> { joins(:agent).where.not(agents: { last_name: nil }) }

  before_save -> { self.authorized_to_export_csv = true }, if: -> { admin? && !authorized_to_export_csv? }
end
