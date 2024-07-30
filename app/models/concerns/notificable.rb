module Notificable
  extend ActiveSupport::Concern

  def notified?
    notifications.any?
  end

  def last_notification
    notifications.max_by(&:created_at)
  end

  def last_notification_created_at
    last_notification&.created_at
  end

  def convocations
    # we assume a convocation is a notification of a created participation
    # since we only send notifications for convocation motifs for now
    notifications.select(&:participation_created?)
  end

  def sms_convocations
    convocations.select(&:format_sms?)
  end

  def email_convocations
    convocations.select(&:format_email?)
  end

  def postal_convocations
    convocations.select(&:format_postal?)
  end

  def last_convocation
    convocations.max_by(&:created_at)
  end

  def last_convocation_created_at
    last_convocation&.created_at
  end
end
