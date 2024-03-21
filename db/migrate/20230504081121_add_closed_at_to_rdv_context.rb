class AddClosedAtToRdvContext < ActiveRecord::Migration[7.0]
  def change
    add_column :follow_ups, :closed_at, :datetime
  end
end
