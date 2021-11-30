module RdvSolidaritesApi
  class RetrieveInvitationToken < Base
    def initialize(rdv_solidarites_session:, rdv_solidarites_user_id:)
      @rdv_solidarites_session = rdv_solidarites_session
      @rdv_solidarites_user_id = rdv_solidarites_user_id
    end

    def call
      retrieve_invitation_token!
    end

    private

    def retrieve_invitation_token!
      fail_with_response_errors unless rdv_solidarites_response.success?

      result.invitation_token = rdv_solidarites_response_body['invitation_token']
    end

    def rdv_solidarites_response
      @rdv_solidarites_response ||= rdv_solidarites_client.invite_user(@rdv_solidarites_user_id)
    end
  end
end
