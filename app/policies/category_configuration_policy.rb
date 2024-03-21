class CategoryConfigurationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      CategoryConfiguration.where(organisation: pundit_user.organisations)
    end
  end
end
