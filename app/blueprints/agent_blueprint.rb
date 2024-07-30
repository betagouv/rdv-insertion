class AgentBlueprint < ApplicationBlueprint
  identifier :id
  fields :email, :first_name, :last_name, :rdv_solidarites_agent_id
  view :extended do
    association :organisations, blueprint: OrganisationBlueprint
  end
end
