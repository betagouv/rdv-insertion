class CreateFileConfigurations < ActiveRecord::Migration[7.0]
  def up
    create_table :file_configurations do |t|
      t.string :sheet_name
      t.jsonb :column_names

      t.timestamps
    end

    add_reference :configurations, :file_configuration, foreign_key: true

    ::Configuration.find_each do |_configuration|
      file_configuration = FileConfiguration.find_or_create_by!(
        sheet_name: category_configuration.sheet_name,
        column_names: category_configuration.column_names
      )
      category_configuration.update! file_configuration_id: file_configuration.id
    end

    remove_column :configurations, :sheet_name
    remove_column :configurations, :column_names
  end

  def down
    add_column :configurations, :sheet_name, :string
    add_column :configurations, :column_names, :json

    ::Configuration.find_each do |configuration|
      file_configuration = FileConfiguration.find(configuration.file_configuration_id)
      category_configuration.update!(
        sheet_name: file_configuration.sheet_name,
        column_names: file_configuration.column_names
      )
    end

    remove_reference :configurations, :file_configuration, foreign_key: true

    drop_table :file_configurations
  end
end
