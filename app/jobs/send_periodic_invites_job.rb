class SendPeriodicInvitesJob < ApplicationJob
  def perform
    @sent_invites_user_ids = []

    RdvContext
      .joins(:invitations)
      .preload(invitations: [{ organisations: :category_configurations }, :user])
      .where(invitations: Invitation.valid)
      .distinct
      .find_each do |rdv_context|
      send_invite(rdv_context)
    end

    notify_on_mattermost
  end

  def send_invite(rdv_context)
    last_invitation = rdv_context.last_invitation
    category_configuration = last_invitation&.current_category_configuration

    return if category_configuration.blank?
    return unless should_send_periodic_invite?(last_invitation, category_configuration)

    @sent_invites_user_ids << last_invitation.user.id

    %w[email sms].each do |format|
      next unless last_invitation.user.can_be_invited_through?(format)

      SendPeriodicInviteJob.perform_async(last_invitation.id, category_configuration.id, format)
    end
  end

  def should_send_periodic_invite?(last_invitation, category_configuration)
    if category_configuration.day_of_the_month_periodic_invites.present?
      Time.zone.today.day == category_configuration.day_of_the_month_periodic_invites
    elsif category_configuration.number_of_days_between_periodic_invites.present?
      (Time.zone.today - last_invitation.created_at.to_date).to_i ==
        category_configuration.number_of_days_between_periodic_invites
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
