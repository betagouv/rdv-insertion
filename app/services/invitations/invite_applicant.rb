module Invitations
  class InviteApplicant < BaseService
    def initialize(applicant:, rdv_solidarites_session:, invitation_format:)
      @applicant = applicant
      @rdv_solidarites_session = rdv_solidarites_session
      @invitation_format = invitation_format
    end

    def call
      retrieve_invitation_token!
      compute_invitation_link!
      create_invitation!
      send_invitation!
      update_invitation_sent_at!
      result.invitation = invitation
    end

    private

    def update_invitation_sent_at!
      return if invitation.update(sent_at: Time.zone.now)

      result.errors << invitation.errors.full_messages.to_sentence
      fail!
    end

    def send_invitation!
      return if send_invitation.success?

      result.errors += send_invitation.errors
      fail!
    end

    def send_invitation
      @send_invitation ||= invitation.send_to_applicant
    end

    def create_invitation!
      return if invitation.save

      result.errors << invitation.errors.full_messages.to_sentence
      fail!
    end

    def invitation
      @invitation ||= Invitation.new(
        applicant: @applicant, format: @invitation_format,
        link: compute_invitation_link.invitation_link,
        token: retrieve_invitation_token.invitation_token
      )
    end

    def retrieve_invitation_token!
      return if retrieve_invitation_token.success?

      result.errors += retrieve_invitation_token.errors
      fail!
    end

    def retrieve_invitation_token
      @retrieve_invitation_token ||= Invitations::RetrieveToken.call(
        rdv_solidarites_session: @rdv_solidarites_session,
        rdv_solidarites_user_id: rdv_solidarites_user_id
      )
    end

    def compute_invitation_link!
      return if compute_invitation_link.success?

      result.errors += compute_invitation_link.errors
      fail!
    end

    def compute_invitation_link
      @compute_invitation_link ||= Invitations::ComputeLink.call(
        department: department,
        rdv_solidarites_session: @rdv_solidarites_session,
        invitation_token: retrieve_invitation_token.invitation_token
      )
    end

    def rdv_solidarites_user_id
      @applicant.rdv_solidarites_user_id
    end

    def department
      @applicant.department
    end
  end
end
