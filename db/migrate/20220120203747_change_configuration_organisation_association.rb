class ChangeConfigurationOrganisationAssociation < ActiveRecord::Migration[6.1]
  def up
    add_reference :organisations, :configuration, foreign_key: true

    Organisation.find_each do |organisation|
      configuration = Configuration.find_by(organisation_id: organisation.id)
      if configuration.blank?
        configuration = Configuration.new(organisation_id: organisation.id,
                                          invitation_format: "sms_and_email")
        configuration.save!
      end

      organisation.update!(configuration_id: configuration.id)
    end

    remove_reference :configurations, :organisation, foreign_key: true
  end

  def down
    add_reference :configurations, :organisation, foreign_key: true

    Configuration.find_each do |config|
      organisation = Organisation.find_by(configuration_id: config.id)
      next unless organisation

      config.update!(organisation_id: organisation.id)
    end

    remove_reference :organisations, :configuration, foreign_key: true
  end
end
