module Invitations
  class SaveAndSend < BaseService
    def initialize(invitation:, rdv_solidarites_session: nil)
      @invitation = invitation
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      Invitation.with_advisory_lock "invite_user_#{user.id}" do
        assign_link_and_token
        validate_invitation
        save_record!(@invitation)
        send_invitation
        update_invitation_sent_at
      end
      result.invitation = @invitation
    end

    private

    def update_invitation_sent_at
      @invitation.sent_at = Time.zone.now
      save_record!(@invitation)
    end

    def validate_invitation
      call_service!(
        Invitations::Validate,
        invitation: @invitation
      )
    end

    def send_invitation
      send_to_user = @invitation.send_to_user
      return if send_to_user.success?

      result.errors += send_to_user.errors
      fail!
    end

    def assign_link_and_token
      return if @invitation.link? && @invitation.rdv_solidarites_token?

      call_service!(
        Invitations::AssignAttributes,
        invitation: @invitation,
        rdv_solidarites_session: @rdv_solidarites_session
      )
    end

    def user
      @invitation.user
    end
  end
end
