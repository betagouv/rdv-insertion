class InvitationMailer < ApplicationMailer
  include ActsAsRdvSolidaritesConcern

  before_action :set_invitation, :set_user, :set_department, :set_signature_lines,
                :set_organisation_logo_path, :set_department_logo_path

  before_action :set_rdv_title, :set_user_designation, :set_mandatory_warning, :set_punishable_warning,
                :set_rdv_purpose, :set_rdv_subject, :set_custom_sentence

  default to: -> { @user.email }, reply_to: -> { "invitation+#{@invitation.uuid}@reply.rdv-insertion.fr" }

  def standard_invitation
    # Le champ "X-Mailin-custom" remonte dans les webhooks
    headers["X-Mailin-custom"] = { "invitation_id" => "#{@invitation.id}" }.to_json
    mail(
      subject: "[#{@rdv_subject.upcase}]: Votre #{@rdv_title} dans le cadre de votre #{@rdv_subject}"
    )
  end

  def short_invitation
    mail(
      subject: "Votre #{@rdv_title}"
    )
  end

  def phone_platform_invitation
    mail(
      subject: "[#{@rdv_subject.upcase}]: Votre #{@rdv_title} dans le cadre de votre #{@rdv_subject}"
    )
  end

  def atelier_invitation
    mail(
      subject: "[#{@rdv_subject.upcase}]: Participer à un atelier dans le cadre de votre parcours"
    )
  end

  def atelier_enfants_ados_invitation
    mail(
      subject: "Invitation à un #{@rdv_title}"
    )
  end

  ### Reminders

  def short_invitation_reminder
    mail(
      subject: "[Rappel]: Votre #{@rdv_title}"
    )
  end

  def standard_invitation_reminder
    mail(
      subject: "[Rappel]: Votre #{@rdv_title} dans le cadre de votre #{@rdv_subject}"
    )
  end

  def phone_platform_invitation_reminder
    mail(
      subject: "[Rappel]: Votre #{@rdv_title} dans le cadre de votre #{@rdv_subject}"
    )
  end

  def atelier_enfants_ados_invitation_reminder
    mail(
      subject: "[Rappel]: Invitation à un #{@rdv_title}"
    )
  end

  private

  def set_invitation
    @invitation = params[:invitation]
  end

  def set_user
    @user = params[:user]
  end

  def set_department
    @department = @invitation.department
  end

  def set_signature_lines
    @signature_lines = @invitation.messages_configuration&.signature_lines
  end

  def set_organisation_logo_path
    return if @invitation.organisations.length != 1 || first_organisation.logo.blank?

    @organisation_logo_path = first_organisation.logo.url
  end

  def set_department_logo_path
    return if @department.logo.blank?

    @department_logo_path = @department.logo.url
  end

  def set_rdv_title
    @rdv_title = @invitation.rdv_title
  end

  def set_rdv_subject
    @rdv_subject = @invitation.rdv_subject
  end

  def set_user_designation
    @user_designation = @invitation.user_designation
  end

  def set_mandatory_warning
    @mandatory_warning = @invitation.mandatory_warning
  end

  def set_punishable_warning
    @punishable_warning = @invitation.punishable_warning
  end

  def set_rdv_purpose
    @rdv_purpose = @invitation.rdv_purpose
  end

  def set_custom_sentence
    @custom_sentence = @invitation.custom_sentence
  end

  def first_organisation
    @invitation.organisations.first
  end
end
