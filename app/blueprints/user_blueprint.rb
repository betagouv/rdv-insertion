class UserBlueprint < Blueprinter::Base
  identifier :id
  fields  :uid, :affiliation_number, :role, :created_at, :department_internal_id,
          :first_name, :last_name, :title, :address, :phone_number, :email, :birth_date, :rights_opening_date,
          :birth_name, :rdv_solidarites_user_id, :nir, :carnet_de_bord_carnet_id

  # Retrocompatibility with old column names
  field :france_travail_id, name: :pole_emploi_id

  view :with_referents do
    association :referents, blueprint: AgentBlueprint
  end

  view :extended do
    association :invitations, blueprint: InvitationBlueprint
    association :organisations, blueprint: OrganisationBlueprint
    association :rdv_contexts, blueprint: RdvContextBlueprint
    association :referents, blueprint: AgentBlueprint
    association :archives, blueprint: ArchiveBlueprint
    association :tags, blueprint: TagBlueprint
  end
end
