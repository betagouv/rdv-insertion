class SendPeriodicInviteJobError < StandardError; end

class SendPeriodicInviteJob < ApplicationJob
  def perform(invitation_id, configuration_id, format, rdv_solidarites_session)
    @invitation = Invitation.find(invitation_id)
    @configuration = Configuration.find(configuration_id)
    @format = format
    @rdv_solidarites_session = rdv_solidarites_session

    return if save_and_send_invitation.success?

    raise SendPeriodicInviteJobError, save_and_send_invitation.errors.join(", ")
  end

  private

  def new_invitation
    new_invitation = @invitation.dup
    new_invitation.format = @format
    new_invitation.reminder = false
    new_invitation.sent_at = nil
    new_invitation.valid_until = @configuration.number_of_days_before_action_required.days.from_now
    new_invitation.organisations = @invitation.organisations
    new_invitation.uuid = nil
    new_invitation.save!
    new_invitation
  end

  def save_and_send_invitation
    @save_and_send_invitation ||= Invitations::SaveAndSend.call(invitation: new_invitation,
                                                                rdv_solidarites_session: @rdv_solidarites_session)
  end
end
