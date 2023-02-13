class AgentRole < ApplicationRecord
  SHARED_ATTRIBUTES_WITH_RDV_SOLIDARITES = [:level].freeze

  belongs_to :agent
  belongs_to :organisation

  validates :level, inclusion: { in: %w[basic admin] }
  validates :rdv_solidarites_agent_role_id, uniqueness: true, allow_nil: true
  validates :agent, uniqueness: { scope: :organisation, message: "est déjà relié à l'organisation" }

  enum level: { basic: 0, admin: 1 }
end
