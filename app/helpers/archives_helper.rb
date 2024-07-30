module ArchivesHelper
  def archived_scope?(scope)
    scope == "archived"
  end

  def organisation_archive(organisation, archives)
    archives.find { |archive| archive.organisation_id == organisation.id }
  end

  def user_archived_in?(user, structure)
    return user.organisation_archive(structure).present? if structure.is_a?(Organisation)

    user_department_archives(user).length == user_agent_department_organisations(user).length
  end

  def user_agent_department_organisations(user)
    user.organisations & current_agent_department_organisations
  end

  def user_department_archives(user)
    user.archives.select do |archive|
      current_agent_department_organisations.map(&:id).include?(archive.organisation_id)
    end
  end
end
