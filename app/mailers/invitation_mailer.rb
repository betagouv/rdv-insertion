class InvitationMailer < ApplicationMailer
  def invitation_for_rsa_orientation(invitation, applicant)
    @invitation = invitation
    @configuration = @invitation.organisations.last.configurations.find_by(context: @invitation.context)
    @applicant = applicant
    mail(
      to: @applicant.email,
      subject: "RDV d'orientation dans le cadre de votre RSA"
    )
  end

  def invitation_for_rsa_accompagnement(invitation, applicant)
    @invitation = invitation
    @configuration = @invitation.organisations.last.configurations.find_by(context: @invitation.context)
    @applicant = applicant
    mail(
      to: @applicant.email,
      subject: "RDV d'accompagnement dans le cadre de votre RSA"
    )
  end

  def invitation_for_rsa_orientation_on_phone_platform(invitation, applicant)
    @invitation = invitation
    @configuration = @invitation.organisations.last.configurations.find_by(context: @invitation.context)
    @applicant = applicant
    mail(
      to: @applicant.email,
      subject: "RDV d'orientation téléphonique dans le cadre de votre RSA"
    )
  end
end
