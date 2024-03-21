class CreateLetterConfigurations < ActiveRecord::Migration[6.1]
  def up
    create_table :letter_configurations do |t|
      t.string :direction_names, array: true
      t.string :sender_city
      t.string :motif, default: "Rendez-vous d’orientation dans le cadre de votre RSA"

      t.timestamps
    end

    add_reference :organisations, :letter_configuration, foreign_key: true

    # assign a default letter_configuration for organisations who already have postal invitations
    postal_configurations = CategoryConfiguration.where("invitation_formats && ?", "{postal}")
    postal_organisations = Organisation.where(configuration_id: postal_configurations.pluck(:id))
    lc = LetterConfiguration.create!(direction_names: [
                                       "DIRECTION GÉNÉRALE DES SERVICES DÉPARTEMENTAUX",
                                       "DIRECTION DE L’INSERTION ET DU RETOUR À L’EMPLOI",
                                       "SERVICE ORIENTATION ET ACCOMPAGNEMENT VERS L’EMPLOI"
                                     ])
    postal_organisations.each do |o|
      o.letter_configuration = lc
      o.save!
    end
  end

  def down
    remove_reference :organisations, :letter_configuration
    drop_table :letter_configurations
  end
end
