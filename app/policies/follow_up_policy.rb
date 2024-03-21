class FollowUpPolicy < ApplicationPolicy
  def create?
    pundit_user.organisation_ids.intersect?(record.user.organisation_ids) &&
      !record.user.deleted? &&
      pundit_user.motif_categories.include?(record.motif_category)
  end

  def close?
    pundit_user.organisation_ids.intersect?(record.user.organisation_ids) &&
      !record.user.deleted? &&
      pundit_user.motif_categories.include?(record.motif_category)
  end

  def reopen?
    close?
  end

  def show?
    record.motif_category_id.in?(pundit_user.motif_category_ids)
  end
end
