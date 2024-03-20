class CreateAndInviteUserJob < ApplicationJob
  sidekiq_options retry: 0

  def perform(organisation_id, user_attributes, invitation_attributes, motif_category_attributes)
    @organisation = Organisation.find(organisation_id)
    @department = @organisation.department
    @user_attributes = user_attributes.deep_symbolize_keys
    @invitation_attributes = invitation_attributes.deep_symbolize_keys
    @motif_category_attributes = motif_category_attributes.deep_symbolize_keys

    upsert_user!
    invite_user
  end

  private

  def upsert_user!
    upsert_user = Users::Upsert.call(
      user_attributes: @user_attributes,
      organisation: @organisation
    )
    @user = upsert_user.user
    return if upsert_user.success?

    notify_department_by_email(upsert_user.errors)
    raise(
      ApplicationJob::FailedServiceError,
      "Error upserting user in CreateAndInviteUserJob: #{upsert_user.errors}"
    )
  end

  def notify_department_by_email(errors)
    DepartmentMailer.create_user_error(@department, @user_attributes, errors).deliver_now
  end

  def invite_user
    enqueue_invite_job("sms") if @user.phone_number_is_mobile?
    enqueue_invite_job("email") if @user.email.present?
  end

  def enqueue_invite_job(invitation_format)
    InviteUserJob.perform_async(
      @user.id,
      @organisation.id,
      @invitation_attributes.merge(format: invitation_format),
      @motif_category_attributes
    )
  end
end
