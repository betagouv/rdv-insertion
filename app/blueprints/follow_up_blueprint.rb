class FollowUpBlueprint < ApplicationBlueprint
  identifier :id
  fields :status, :human_status, :motif_category_id, :closed_at
  association :participations, blueprint: ParticipationBlueprint
end
