class InvitationPolicy < ApplicationPolicy
  def create?
    pundit_user.organisation_ids.intersect?(record.user.organisation_ids)
  end

  def show?
    record.follow_up.motif_category_id.in?(pundit_user.motif_category_ids)
  end
end
