class AddExternalNotificationsToCategoryConfiguration < ActiveRecord::Migration[7.1]
  def change
    add_column :category_configurations, :notify_rdv_changes, :boolean, default: false
    add_column :category_configurations, :notify_rdv_changes_email, :string
    add_column :category_configurations, :notify_out_of_slots, :boolean, default: false
    add_column :category_configurations, :notify_out_of_slots_email, :string
  end
end
