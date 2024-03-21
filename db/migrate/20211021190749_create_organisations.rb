# This migration creates the organisation table exactly like the department one
# and fills it with the departments table values
class CreateOrganisations < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def up
    create_table :organisations do |t|
      t.string :name
      t.string :number
      t.string :capital
      t.string :region
      t.string :phone_number
      t.string :email
      t.integer :rdv_solidarites_organisation_id

      t.timestamps
    end

    add_index "organisations", ["rdv_solidarites_organisation_id"], unique: true

    create_join_table :organisations, :agents do |t|
      t.index [:organisation_id, :agent_id], unique: true
    end

    create_join_table :organisations, :applicants do |t|
      t.index(
        [:organisation_id, :applicant_id],
        unique: true,
        name: "index_applicants_orgas_on_orga_id_and_applicant_id"
      )
    end

    add_reference :invitations, :organisation, foreign_key: true
    add_reference :configurations, :organisation, foreign_key: true
    add_reference :rdvs, :organisation, foreign_key: true

    Department.find_each do |department|
      organisation = Organisation.new(
        name: department.name,
        number: department.number,
        capital: department.capital,
        phone_number: department.phone_number,
        rdv_solidarites_organisation_id: department.rdv_solidarites_organisation_id,
        category_configuration: department.configuration,
        agents: department.agents,
        rdvs: department.rdvs,
        applicants: department.applicants
      )
      organisation.save!(validate: false)
    end

    remove_reference :invitations, :department, null: false, foreign_key: true
    remove_reference :configurations, :department, null: false, foreign_key: true
    remove_reference :rdvs, :department, null: false, foreign_key: true
  end

  def down
    add_reference :invitations, :department, foreign_key: true
    add_reference :configurations, :department, foreign_key: true
    add_reference :rdvs, :department, foreign_key: true

    Department.find_each do |department|
      organisation = Organisation.find_by!(
        rdv_solidarites_organisation_id: department.rdv_solidarites_organisation_id
      )
      department.rdvs = organisation.rdvs
      department.configuration = organisation.configuration
      department.invitations = organisation.invitations
      department.save!(validate: false)
    end

    remove_reference :invitations, :organisation, foreign_key: true
    remove_reference :configurations, :organisation, foreign_key: true
    remove_reference :rdvs, :organisation, foreign_key: true

    drop_table :applicants_organisations
    drop_table :agents_organisations
    drop_table :organisations
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
