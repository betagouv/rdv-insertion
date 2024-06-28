class AddDeliveryStatusAndDeliveredAtToInvitations < ActiveRecord::Migration[7.1]
  def change
    add_column :invitations, :delivery_status, :string
    add_column :invitations, :delivered_at, :datetime
  end
end
