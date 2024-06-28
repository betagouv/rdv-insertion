class AddDeliveryStatusAndDeliveredAtToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :notifications, :delivery_status, :string
    add_column :notifications, :delivered_at, :datetime
  end
end
