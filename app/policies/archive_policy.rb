class ArchivePolicy < ApplicationPolicy
  def create?
    pundit_user.organisation_ids.include?(record.organisation_id)
  end

  def show? = create?

  def destroy? = create?

  def resolve
    Archive.where(organisation_id: pundit_user.organisations.pluck(:id))
  end
end
