class InviteUserJob < ApplicationJob
  sidekiq_options retry: 10

  def perform(
    user_id, organisation_id, invitation_attributes, motif_category_attributes, rdv_solidarites_session_credentials
  )
    @user = User.find(user_id)
    @organisation = Organisation.find(organisation_id)
    @invitation_attributes = invitation_attributes.deep_symbolize_keys
    @motif_category_attributes = motif_category_attributes
    @rdv_solidarites_session_credentials = rdv_solidarites_session_credentials.deep_symbolize_keys

    Invitation.with_advisory_lock "invite_user_job_#{@user.id}" do
      invite_user!
    end
  end

  private

  def invite_user!
    invite_user = InviteUser.call(
      user: @user,
      organisations: [@organisation],
      invitation_attributes: @invitation_attributes,
      motif_category_attributes: @motif_category_attributes,
      rdv_solidarites_session:
    )
    return if invite_user.success?

    raise(
      FailedServiceError,
      "Could not send invitation to user #{@user.id} in InviteUserJob: " \
      "#{invite_user.errors}"
    )
  end

  def rdv_solidarites_session
    @rdv_solidarites_session ||= RdvSolidaritesSessionFactory.create_with(**@rdv_solidarites_session_credentials)
  end
end
