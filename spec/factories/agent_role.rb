FactoryBot.define do
  factory :agent_role do
    organisation
    agent
    access_level { "basic" }
    sequence(:rdv_solidarites_agent_role_id)
    authorized_to_export_csv { false }
  end
end
