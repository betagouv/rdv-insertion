module Deliverable
  extend ActiveSupport::Concern

  FINAL_DELIVERY_STATUS = %w[delivered soft_bounce hard_bounce blocked invalid_email error].freeze
  FAILED_DELIVERY_STATUS = %w[soft_bounce hard_bounce blocked invalid_email error].freeze

  included do
    # https://developers.brevo.com/docs/transactional-webhooks
    enum delivery_status: { accepted: "accepted", sent: "sent", request: "request", click: "click",
                            deferred: "deferred", delivered: "delivered", hard_bounce: "hard_bounce",
                            soft_bounce: "soft_bounce", spam: "spam", unique_opened: "unique_opened", opened: "opened",
                            reply: "reply", invalid_email: "invalid_email", blocked: "blocked", error: "error",
                            unsubscribe: "unsubscribe", proxy_open: "proxy_open" }

    validates :delivered_at, presence: true, if: -> { delivery_status.present? }
  end

  def human_delivery_status_and_date
    if delivery_status == "delivered"
      if delivery_date == creation_date
        "Délivrée à #{delivery_hour}"
      else
        "Délivrée à #{delivery_hour} (le #{delivery_date})"
      end
    elsif delivery_status.in?(FAILED_DELIVERY_STATUS)
      "Non délivrée"
    end
  end

  def creation_date
    created_at.strftime("%d/%m/%Y")
  end

  def delivery_date
    delivered_at&.strftime("%d/%m/%Y")
  end

  def delivery_hour
    delivered_at&.strftime("%H:%M")
  end

  def record_identifier
    "#{self.class.name.underscore}_#{id}"
  end
end
