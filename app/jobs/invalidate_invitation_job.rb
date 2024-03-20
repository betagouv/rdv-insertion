class InvalidateInvitationJobError < StandardError; end

class InvalidateInvitationJob < ApplicationJob
  def perform(invitation_id)
    invitation = Invitation.find(invitation_id)
    return if invitation.expired?

    call_service!(Invitations::InvalidateLink, invitation:)
  end
end
