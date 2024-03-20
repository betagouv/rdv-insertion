class WebhookReceipt < ApplicationRecord
  belongs_to :webhook_endpoint, optional: true

  validates :resource_model, :resource_id, :timestamp, presence: true

  # france travail webhooks are not linked to a webhook_endpoint
  scope :france_travail, -> { where(webhook_endpoint_id: nil) }
end
