class NotificationsJobError < StandardError; end

class NotifyParticipationToUserJob < ApplicationJob
  def perform(participation_id, format, event)
    @participation = Participation.find(participation_id)
    @format = format
    @event = event

    return unless @participation.notifiable? && user.notifiable?
    return if reminder_of_cancelled_participation?

    Notification.with_advisory_lock "notifying_particpation_#{@participation.id}" do
      return if already_notified?

      save_and_send_notification!
    end
  end

  private

  def user
    @participation.user
  end

  def already_notified?
    if @event == "participation_updated"
      # we assume here there should not be more than 2 lieu/time updates in one hour. The mattermost notification
      # would let us double check anyway.
      @participation.notifications
                    .where(event: "participation_updated", format: @format)
                    .where("created_at > ?", 1.hour.ago).count > 1
    else
      @participation.notifications.find_by(event: @event, format: @format).present?
    end
  end

  def save_and_send_notification!
    call_service!(
      Notifications::SaveAndSend,
      participation: @participation, format: @format, event: @event
    )
  end

  def reminder_of_cancelled_participation?
    @event == "participation_reminder" && @participation.cancelled?
  end
end
