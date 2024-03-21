class RenameRdvContextsToFollowUps < ActiveRecord::Migration[7.1]
  def change
    rename_table :rdv_contexts, :follow_ups
    rename_column :invitations, :rdv_context_id, :follow_up_id
    rename_column :participations, :rdv_context_id, :follow_up_id
  end
end
