class AddRdvContextToParticipations < ActiveRecord::Migration[7.0]
  def up
    add_reference :participations, :follow_up, foreign_key: true
    execute(<<-SQL.squish
      UPDATE participations SET
      follow_up_id = (
        SELECT follow_ups.id FROM follow_ups
        JOIN follow_ups_rdvs ON follow_ups_rdvs.follow_up_id = follow_ups.id
        JOIN rdvs ON follow_ups_rdvs.rdv_id = rdvs.id
        WHERE participations.applicant_id = follow_ups.applicant_id
        AND participations.rdv_id = rdvs.id)
    SQL
           )
    drop_table :follow_ups_rdvs
  end

  def down
    create_join_table :rdvs, :follow_ups do |t|
      t.index([:rdv_id, :follow_up_id], unique: true)
    end
    execute(<<-SQL.squish
      INSERT INTO follow_ups_rdvs (follow_up_id, rdv_id)
      SELECT follow_up_id, rdv_id FROM participations
    SQL
           )
    remove_reference :participations, :follow_up, foreign_key: true
  end
end
