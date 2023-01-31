class SendInvitationRemindersJob < ApplicationJob
  def perform
    return if staging_env?

    @sent_reminders_applicant_ids = []

    applicants_to_send_reminders_to.find_each do |applicant|
      # we check here that it is the **first** invitation that has been sent 3 days ago
      next if applicant.first_invitation_relative_to_last_participation_sent_at.to_date != 3.days.ago.to_date

      SendInvitationReminderJob.perform_async(applicant.id, "email") if applicant.email?
      if applicant.phone_number? && applicant.phone_number_is_mobile?
        SendInvitationReminderJob.perform_async(applicant.id, "sms")
      end
      @sent_reminders_applicant_ids << applicant.id
    end

    notify_on_mattermost
  end

  private

  def applicants_to_send_reminders_to
    @applicants_to_send_reminders_to ||= \
      Applicant.active
               .archived(false)
               .where(id: valid_invitations_sent_3_days_ago.pluck(:applicant_id))
               .distinct
  end

  def staging_env?
    ENV["SENTRY_ENVIRONMENT"] == "staging"
  end

  def valid_invitations_sent_3_days_ago
    @valid_invitations_sent_3_days_ago ||= \
      # we want the token to be valid for at least two days to be sure the invitation will be valid
      Invitation.where("valid_until > ?", 2.days.from_now)
                .where(format: %w[email sms], sent_at: 3.days.ago.all_day, reminder: false)
                .joins(:rdv_context)
                .where(
                  rdv_contexts: RdvContext.invitation_pending.joins(:motif_category).where(
                    # ateliers are open invitations so we don't send reminders
                    motif_category: MotifCategory.not_atelier
                  )
                )
  end

  def notify_on_mattermost
    MattermostClient.send_to_notif_channel(
      "📬 #{@sent_reminders_applicant_ids.length} relances en cours!\n" \
      "Les allocataires sont: #{@sent_reminders_applicant_ids}"
    )
  end
end
