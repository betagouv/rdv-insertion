class SendPeriodicInvitesJob < ApplicationJob
  def perform
    @sent_invites_user_ids = []

    FollowUp
      .joins(:invitations)
      .preload(invitations: [{ organisations: :configurations }, :user])
      .where(invitations: Invitation.valid)
      .distinct
      .find_each do |follow_up|
      send_invite(follow_up)
    end

    notify_on_mattermost
  end

  def send_invite(follow_up)
    last_invitation = follow_up.last_invitation
    configuration = last_invitation&.current_configuration

    return if configuration.blank?
    return unless should_send_periodic_invite?(last_invitation, configuration)

    @sent_invites_user_ids << last_invitation.user.id

    %w[email sms].each do |format|
      next unless last_invitation.user.can_be_invited_through?(format)

      SendPeriodicInviteJob.perform_async(last_invitation.id, configuration.id, format)
    end
  end

  def should_send_periodic_invite?(last_invitation, configuration)
    if configuration.day_of_the_month_periodic_invites.present?
      Time.zone.today.day == configuration.day_of_the_month_periodic_invites
    elsif configuration.number_of_days_between_periodic_invites.present?
      (Time.zone.today - last_invitation.created_at.to_date).to_i ==
        configuration.number_of_days_between_periodic_invites
    else
      false
    end
  end

  def notify_on_mattermost
    MattermostClient.send_to_notif_channel(
      "📬 #{@sent_invites_user_ids.length} invitations périodiques envoyées!\n" \
      "Les usagers sont: #{@sent_invites_user_ids}"
    )
  end
end
