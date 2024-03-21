class RenameLetterConfigurationTableInInvitationParameters < ActiveRecord::Migration[7.0]
  def up
    rename_table :letter_configurations, :invitation_parameters
    rename_column :organisations, :letter_configuration_id, :invitation_parameters_id
    rename_column :invitation_parameters, :sender_name, :letter_sender_name
    add_column :invitation_parameters, :sms_sender_name, :string
    add_column :invitation_parameters, :signature_lines, :string, array: true
    configure_signature_and_sms_sender_name_on_invitation_parameters
    remove_column :configurations, :sms_sender_name
  end

  def down
    add_column :configurations, :sms_sender_name, :string
    set_sms_sender_name_on_configuration
    remove_column :invitation_parameters, :signature_lines
    remove_column :invitation_parameters, :sms_sender_name
    rename_column :invitation_parameters, :letter_sender_name, :sender_name
    rename_table :invitation_parameters, :letter_configurations
    rename_column :organisations, :invitation_parameters_id, :letter_configuration_id
  end

  def configure_signature_and_sms_sender_name_on_invitation_parameters
    Organisation.find_each do |organisation|
      next unless (invitation_parameters = organisation.invitation_parameters)

      invitation_parameters.sms_sender_name = organisation.configurations.first.sms_sender_name
      if organisation.responsible.present?
        invitation_parameters.signature_lines =
          ["Pour le Président du Conseil départemental et par délégation,",
           "#{organisation.responsible.full_name}, #{organisation.responsible.role}"]
      end
      invitation_parameters.save!
    end
  end

  def set_sms_sender_name_on_configuration
    CategoryConfiguration.find_each do |_configuration|
      next unless (invitation_parameters = category_configuration.organisations.first.invitation_parameters)

      category_configuration.sms_sender_name = invitation_parameters.sms_sender_name
      category_configuration.save!
    end
  end
end
