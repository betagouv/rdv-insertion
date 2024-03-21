class CreateMotifCategories < ActiveRecord::Migration[7.0]
  CATEGORIES_ENUM = {
    rsa_orientation: 0,
    rsa_accompagnement: 1,
    rsa_orientation_on_phone_platform: 2,
    rsa_cer_signature: 3,
    rsa_insertion_offer: 4,
    rsa_follow_up: 5,
    rsa_accompagnement_social: 6,
    rsa_accompagnement_sociopro: 7,
    rsa_main_tendue: 8,
    rsa_atelier_collectif_mandatory: 9,
    rsa_spie: 10,
    rsa_integration_information: 11,
    rsa_atelier_competences: 12,
    rsa_atelier_rencontres_pro: 13
  }.freeze
  CATEGORIES_NAMES = {
    rsa_orientation: "RSA orientation",
    rsa_accompagnement: "RSA accompagnement",
    rsa_accompagnement_social: "RSA accompagnement social",
    rsa_accompagnement_sociopro: "RSA accompagnement socio-pro",
    rsa_orientation_on_phone_platform: "RSA orientation sur plateforme téléphonique",
    rsa_cer_signature: "RSA signature CER",
    rsa_insertion_offer: "RSA offre insertion pro",
    rsa_follow_up: "RSA suivi",
    rsa_main_tendue: "RSA Main Tendue",
    rsa_atelier_collectif_mandatory: "RSA Atelier collectif obligatoire",
    rsa_spie: "RSA SPIE",
    rsa_integration_information: "RSA Information d'intégration",
    rsa_atelier_competences: "RSA Atelier compétences",
    rsa_atelier_rencontres_pro: "RSA Atelier rencontres professionnelles"
  }.freeze

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def up
    create_table :motif_categories do |t|
      t.string :short_name
      t.string :name
      t.bigint :rdv_solidarites_motif_category_id

      t.timestamps
    end

    add_index "motif_categories", ["short_name"], unique: true
    add_index "motif_categories", ["rdv_solidarites_motif_category_id"], unique: true

    rename_column :configurations, :motif_category, :old_motif_category
    rename_column :rdv_contexts, :motif_category, :old_motif_category

    add_reference :configurations, :motif_category, foreign_key: true
    add_reference :rdv_contexts, :motif_category, foreign_key: true
    add_reference :motifs, :motif_category, foreign_key: true

    CATEGORIES_ENUM.each do |short_name, enum_value|
      motif_category = MotifCategory.create!(
        short_name: short_name,
        name: CATEGORIES_NAMES[short_name]
      )
      CategoryConfiguration.where(old_motif_category: enum_value).find_each do |c|
        c.update! motif_category_id: motif_category.id
      end
      RdvContext.where(old_motif_category: enum_value).find_each do |rdvc|
        rdvc.update! motif_category_id: motif_category.id
      end
      Motif.where(category: enum_value).find_each { |m| m.update! motif_category_id: motif_category.id }
    end

    remove_column :configurations, :old_motif_category
    remove_column :rdv_contexts, :old_motif_category
    remove_column :motifs, :category
  end

  def down
    add_column :configurations, :old_motif_category, :integer
    add_column :rdv_contexts, :old_motif_category, :integer
    add_column :motifs, :category, :integer

    CATEGORIES_ENUM.each do |short_name, enum_value|
      motif_category = MotifCategory.find_by! short_name: short_name
      CategoryConfiguration.where(motif_category_id: motif_category.id).find_each do |c|
        c.update! old_motif_category: enum_value
      end
      RdvContext.where(motif_category_id: motif_category.id).find_each do |rdvc|
        rdvc.update! old_motif_category: enum_value
      end
      Motif.where(motif_category_id: motif_category.id).find_each { |m| m.update! category: enum_value }
    end

    remove_reference :configurations, :motif_category
    remove_reference :rdv_contexts, :motif_category
    remove_reference :motifs, :motif_category

    rename_column :configurations, :old_motif_category, :motif_category
    rename_column :rdv_contexts, :old_motif_category, :motif_category

    add_index "configurations", "motif_category"
    add_index "rdv_contexts", "motif_category"
    add_index "motifs", "category"

    drop_table :motif_categories
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
