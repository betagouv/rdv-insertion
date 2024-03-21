class RenameCustomIdToDepartmentInternalId < ActiveRecord::Migration[6.1]
  def up
    rename_column :applicants, :custom_id, :department_internal_id
    add_index "applicants", %w[department_internal_id department_id], unique: true

    CategoryConfiguration.find_each do |config|
      next if config.column_names.dig("optional", "custom_id").blank?

      config.column_names["optional"]["department_internal_id"] = config.column_names["optional"].delete("custom_id")
      config.save!
    end
  end

  def down
    CategoryConfiguration.find_each do |config|
      next if config.column_names.dig("optional", "department_internal_id").blank?

      config.column_names["optional"]["custom_id"] = config.column_names["optional"].delete("department_internal_id")
      config.save!
    end

    remove_index "applicants", ["department_internal_id, department_id"]
    rename_column :applicants, :department_internal_id, :custom_id
  end
end
