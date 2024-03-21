class SendPeriodicInviteJob < ApplicationJob
  def perform(invitation_id, configuration_id, format)
    @invitation = Invitation.find(invitation_id)
    @configuration = Configuration.find(configuration_id)
    @format = format

    return if invitation_already_sent_today?

    send_invitation
  end

  private

  def send_invitation
    new_invitation = @invitation.dup

    new_invitation.format = @format
    new_invitation.reminder = false
    new_invitation.valid_until = @configuration.number_of_days_before_action_required.days.from_now
    new_invitation.organisations = @invitation.organisations
    new_invitation.uuid = nil
    new_invitation.save!

    Invitations::SaveAndSend.call(invitation: new_invitation, check_creneaux_availability: false)
  end

  def invitation_already_sent_today?
    @invitation.follow_up.invitations
               .where(format: @format)
               .where("created_at > ?", 24.hours.ago)
               .any?
  end
end
