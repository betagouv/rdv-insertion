module Notifications
  class NotifyParticipation < BaseService
    def initialize(participation:, event:, format:)
      @participation = participation
      @event = event
      @format = format
    end

    def call
      Notification.transaction do
        save_record!(notification)
        send_notification
      end
      update_notification_sent_at
      result.notification = notification
    end

    private

    def notification
      @notification ||= Notification.new(
        participation: @participation,
        event: @event,
        format: @format,
        # needed in case the rdv gets deleted
        rdv_solidarites_rdv_id: @participation.rdv_solidarites_rdv_id
      )
    end

    def send_notification
      send_to_user = @notification.send_to_user
      return if send_to_user.success?

      result.errors += send_to_user.errors
      fail!
    end

    def update_notification_sent_at
      notification.sent_at = Time.zone.now
      save_record!(notification)
    end
  end
end
