class InviteUserJob < ApplicationJob
  sidekiq_options retry: 10

  def perform(user_id, organisation_id, invitation_attributes, motif_category_attributes)
    @user = User.find(user_id)
    @organisation = Organisation.find(organisation_id)
    @invitation_attributes = invitation_attributes.deep_symbolize_keys
    @motif_category_attributes = motif_category_attributes

    Invitation.with_advisory_lock "invite_user_job_#{@user.id}" do
      invite_user!
    end
  end

  private

  def invite_user!
    call_service!(
      InviteUser,
      user: @user,
      organisations: [@organisation],
      invitation_attributes: @invitation_attributes,
      motif_category_attributes: @motif_category_attributes,
      check_creneaux_availability: false
    )
  end
end
