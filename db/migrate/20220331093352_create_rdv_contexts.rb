class CreateRdvContexts < ActiveRecord::Migration[6.1]
  def change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    create_table :follow_ups do |t|
      t.integer :context
      t.integer :status
      t.references :applicant, null: false, foreign_key: true

      t.timestamps
    end

    create_join_table :rdvs, :follow_ups do |t|
      t.index([:rdv_id, :follow_up_id], unique: true)
    end

    add_reference :invitations, :follow_up, foreign_key: true

    add_index "follow_ups", ["context"]
    add_index "follow_ups", ["status"]

    up_only do
      Applicant.find_each do |applicant|
        next if applicant.not_invited?

        follow_up = FollowUp.new(applicant: applicant, context: "rsa_orientation")
        follow_up.save!

        follow_up.rdvs = applicant.rdvs
        follow_up.invitations = applicant.invitations

        follow_up.save!
      end
    end
  end
end
