class RenameConfigurationsToCategoryConfigurations < ActiveRecord::Migration[7.1]
  def change
    rename_table :configurations, :category_configurations
  end
end
