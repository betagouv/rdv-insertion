class SendInvitationRemindersJob < ApplicationJob
  def perform
    @sent_reminders_user_ids = []

    follow_ups_with_reminder_needed.find_each do |follow_up|
      invitation = follow_up.first_invitation_relative_to_last_participation
      # we check here that the **first** invitation has been sent Invitation::NUMBER_OF_DAYS_BEFORE_REMINDER
      # number of days ago with that value being set to 3
      next unless invitation_sent_3_days_ago?(invitation)

      user = follow_up.user

      SendInvitationReminderJob.perform_async(follow_up.id, "email") if user.email?
      SendInvitationReminderJob.perform_async(follow_up.id, "sms") if user.phone_number_is_mobile?

      @sent_reminders_user_ids << user.id
    end

    notify_on_mattermost
  end

  private

  def follow_ups_with_reminder_needed
    @follow_ups_with_reminder_needed ||=
      FollowUp.invitation_pending
              .joins(:motif_category)
              .where(motif_category: MotifCategory.optional_rdv_subscription(false))
              .where(id: valid_invitations_sent_3_days_ago.pluck(:follow_up_id))
              .where(user_id: User.active.select(:id))
              .distinct
  end

  def valid_invitations_sent_3_days_ago
    @valid_invitations_sent_3_days_ago ||=
      # we want the token to be valid for at least two days to be sure the invitation will be valid
      Invitation.where("valid_until > ?", 2.days.from_now)
                .where(
                  format: %w[email sms],
                  created_at: Invitation::NUMBER_OF_DAYS_BEFORE_REMINDER.days.ago.all_day
                )
                .not_reminder
  end

  def invitation_sent_3_days_ago?(invitation)
    invitation.created_at.to_date == Invitation::NUMBER_OF_DAYS_BEFORE_REMINDER.days.ago.to_date
  end

  def notify_on_mattermost
    MattermostClient.send_to_notif_channel(
      "📬 #{@sent_reminders_user_ids.length} relances en cours!\n" \
      "Les usagers sont: #{@sent_reminders_user_ids}"
    )
  end
end
