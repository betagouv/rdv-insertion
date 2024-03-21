class ChangeConfigurationOrganisationAssociation < ActiveRecord::Migration[6.1]
  def up
    add_reference :organisations, :configuration, foreign_key: true

    Organisation.find_each do |organisation|
      category_configuration = CategoryConfiguration.find_by(organisation_id: organisation.id)
      if category_configuration.blank?
        category_configuration = CategoryConfiguration.new(organisation_id: organisation.id,
                                                           invitation_format: "sms_and_email")
        category_configuration.save!
      end

      organisation.update!(configuration_id: category_configuration.id)
    end

    remove_reference :configurations, :organisation, foreign_key: true
  end

  def down
    add_reference :configurations, :organisation, foreign_key: true

    CategoryConfiguration.find_each do |config|
      organisation = Organisation.find_by(configuration_id: config.id)
      next unless organisation

      config.update!(organisation_id: organisation.id)
    end

    remove_reference :organisations, :configuration, foreign_key: true
  end
end
