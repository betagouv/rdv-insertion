class NotificationMailerError < StandardError; end

class NotificationMailer < ApplicationMailer
  include ActsAsRdvSolidaritesConcern

  before_action :set_notification, :set_user, :set_rdv, :set_department, :set_rdv_subject,
                :set_signature_lines, :set_rdv_title, :set_rdv_title_by_phone, :set_user_designation,
                :set_mandatory_warning, :set_punishable_warning, :set_instruction_for_rdv,
                :set_rdv_purpose, :verify_phone_number_presence, :set_organisation_logo_path, :set_department_logo_path

  default to: -> { @user.email }, reply_to: -> { "rdv+#{@rdv.uuid}@reply.rdv-insertion.fr" }

  ### participation_created ###
  def presential_participation_created
    mail(
      subject: "[Important - #{@rdv_subject.upcase}] Vous êtes #{@user.conjugate('convoqué')}" \
               " à un #{@rdv_title}"
    )
  end

  def by_phone_participation_created
    mail(
      subject: "[Important - #{@rdv_subject.upcase}] Vous êtes #{@user.conjugate('convoqué')}" \
               " à un #{@rdv_title_by_phone}"
    )
  end

  ### participation_updated ###
  def presential_participation_updated
    mail(
      subject: "[Important - #{@rdv_subject.upcase}] Votre #{@rdv_title} a été modifié"
    )
  end

  def by_phone_participation_updated
    mail(
      subject: "[Important - #{@rdv_subject.upcase}] Votre #{@rdv_title_by_phone} a été modifié"
    )
  end

  ## participation_reminder ###

  def presential_participation_reminder
    mail(
      subject: "[Rappel - #{@rdv_subject.upcase}] Vous êtes #{@user.conjugate('convoqué')}" \
               " à un #{@rdv_title}"
    )
  end

  def by_phone_participation_reminder
    mail(
      subject: "[Rappel - #{@rdv_subject.upcase}] Vous êtes #{@user.conjugate('convoqué')}" \
               " à un #{@rdv_title_by_phone}"
    )
  end

  ### participation_cancelled ###
  def participation_cancelled
    mail(
      subject: "[Important - #{@rdv_subject.upcase}] Votre #{@rdv_title} a été annulé"
    )
  end

  private

  def set_notification
    @notification = params[:notification]
  end

  def set_user
    @user = @notification.user
  end

  def set_rdv
    @rdv = @notification.rdv
  end

  def set_department
    @department = @notification.department
  end

  def set_signature_lines
    @signature_lines = @notification.signature_lines
  end

  def set_rdv_title
    @rdv_title = @notification.rdv_title
  end

  def set_rdv_title_by_phone
    @rdv_title_by_phone = @notification.rdv_title_by_phone
  end

  def set_rdv_subject
    @rdv_subject = @notification.rdv_subject
  end

  def set_user_designation
    @user_designation = @notification.user_designation
  end

  def set_mandatory_warning
    @mandatory_warning = @notification.mandatory_warning
  end

  def set_punishable_warning
    @punishable_warning = @notification.punishable_warning
  end

  def set_instruction_for_rdv
    @instruction_for_rdv = @notification.instruction_for_rdv
  end

  def set_rdv_purpose
    @rdv_purpose = @notification.rdv_purpose
  end

  def set_organisation_logo_path
    return if @rdv.organisation.logo.blank?

    @organisation_logo_path = @rdv.organisation.logo.url
  end

  def set_department_logo_path
    @department_logo_path = @department.logo.url
  end

  def rdv_by_phone?
    action_name.include?("by_phone")
  end

  def verify_phone_number_presence
    # if we send a notif for a phone rdv we want to be sure the user has a phone
    return unless rdv_by_phone?
    return if @user.phone_number.present?

    raise(
      NotificationMailerError,
      "No valid phone found for user #{@user.id}, cannot notify him by phone"
    )
  end
end
