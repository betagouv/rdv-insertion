class UserBlueprint < ApplicationBlueprint
  identifier :id
  fields  :uid, :affiliation_number, :role, :created_at, :department_internal_id,
          :first_name, :last_name, :title, :address, :phone_number, :email, :birth_date, :rights_opening_date,
          :birth_name, :rdv_solidarites_user_id, :nir, :carnet_de_bord_carnet_id, :france_travail_id

  view :with_referents do
    association :referents, blueprint: AgentBlueprint
  end

  view :extended do
    association :organisations, blueprint: OrganisationBlueprint
    association :referents, blueprint: AgentBlueprint
    association :archives, blueprint: ArchiveBlueprint

    policy_scoped_association :invitations, blueprint: InvitationBlueprint
    policy_scoped_association :follow_ups, blueprint: FollowUpBlueprint
    policy_scoped_association :tags, blueprint: TagBlueprint
  end
end
