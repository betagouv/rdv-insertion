module AgentRoles
  class ManageExportAuthorizationsForAnOrganisation < BaseService
    def initialize(organisation:, agent_roles:)
      @organisation = organisation
      @agent_roles_with_authorization_granted = agent_roles
    end

    def call
      AgentRole.transaction do
        authorize_agent_roles_to_export
        unauthorize_agent_roles_to_export
      end
    end

    private

    def authorize_agent_roles_to_export
      return if agent_roles_to_authorize_to_export_csv.empty?

      agent_roles_to_authorize_to_export_csv.update_all(authorized_to_export_csv: true)
    end

    def unauthorize_agent_roles_to_export
      return if agent_roles_to_unauthorize_to_export_csv.empty?

      agent_roles_to_unauthorize_to_export_csv.update_all(authorized_to_export_csv: false)
    end

    def agent_roles_to_authorize_to_export_csv
      @agent_roles_to_authorize_to_export_csv ||=
        @agent_roles_with_authorization_granted.where.not(id: basic_agent_roles_authorized_in_organisation.select(:id))
    end

    def agent_roles_to_unauthorize_to_export_csv
      @agent_roles_to_unauthorize_to_export_csv ||=
        basic_agent_roles_authorized_in_organisation.where.not(id: @agent_roles_with_authorization_granted.select(:id))
    end

    def basic_agent_roles_authorized_in_organisation
      @basic_agent_roles_authorized_in_organisation ||= @organisation.agent_roles.basic.authorized_to_export_csv
    end
  end
end
