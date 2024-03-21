class ChangeOrganisationConfigurationRelation < ActiveRecord::Migration[7.0]
  def up
    add_reference :configurations, :organisation, foreign_key: true

    # the model ConfigurationsOrganisation do not exist anymore, so we access the records with sql
    configurations_organisations = ActiveRecord::Base.connection.execute("SELECT * FROM configurations_organisations")

    configurations_organisations.to_a.each do |config_org|
      category_configuration = ::Configuration.find(config_org["configuration_id"])
      category_configuration.organisation_id = config_org["organisation_id"]
      category_configuration.save!
    end

    drop_table :configurations_organisations
  end

  def down
    create_join_table :organisations, :configurations do |t|
      t.index(
        [:organisation_id, :configuration_id],
        unique: true,
        name: "index_config_orgas_on_organisation_id_and_configuration_id"
      )
    end

    ::Configuration.find_each do |configuration|
      # we insert with sql because the model ConfigurationsOrganisation and associated relations do not exist anymore
      ActiveRecord::Base.connection.insert(
        "INSERT INTO configurations_organisations (configuration_id, organisation_id)
         VALUES (#{configuration.id}, #{configuration.organisation_id})"
      )
    end

    remove_reference :configurations, :organisation, null: false, foreign_key: true
  end
end
