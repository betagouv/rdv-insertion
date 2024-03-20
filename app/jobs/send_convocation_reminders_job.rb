class SendConvocationRemindersJob < ApplicationJob
  def perform
    return if staging_env?

    NotifyParticipationsToUsersJob.perform_async(participations_to_send_reminders_to.ids, "reminder")
    notify_on_mattermost
  end

  private

  def participations_to_send_reminders_to
    @participations_to_send_reminders_to ||=
      Participation.joins(:rdv)
                   .where(convocable: true)
                   .where(rdvs: { starts_at: 2.days.from_now.all_day })
                   .not_cancelled
  end

  def notify_on_mattermost
    MattermostClient.send_to_notif_channel(
      "📅 #{participations_to_send_reminders_to.ids.length} rappels de convocation en cours d'envoi!\n" \
      "Les participations sont: #{participations_to_send_reminders_to.ids}"
    )
  end
end
