class RemoveNotNullConstraintFromWebhookEndpointsInWebhookReceipts < ActiveRecord::Migration[7.1]
  def change
    change_column_null :webhook_receipts, :webhook_endpoint_id, true
  end
end
