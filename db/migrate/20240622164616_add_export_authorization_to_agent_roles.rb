class AddExportAuthorizationToAgentRoles < ActiveRecord::Migration[7.1]
  def change
    add_column :agent_roles, :authorized_to_export_csv, :boolean, default: false

    AgentRole.admin.update_all(authorized_to_export_csv: true)
  end
end
