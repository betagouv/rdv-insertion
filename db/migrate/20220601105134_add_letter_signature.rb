class AddLetterSignature < ActiveRecord::Migration[7.0]
  def change
    add_column :letter_configurations, :signature_lines, :string, array: true
    Organisation.all.each do |organisation|
      next if organisation.responsible.blank? || organisation.letter_configuration.blank?

      organisation.letter_configuration.signature_lines =
        ["Pour le Président du Conseil départemental et par délégation,",
         "#{organisation.responsible.full_name}, #{organisation.responsible.role}"]
      organisation.letter_configuration.save!
    end
  end
end
