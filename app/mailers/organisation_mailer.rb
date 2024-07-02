class OrganisationMailer < ApplicationMailer
  def user_added(to:, subject:, content:, user_attachements:, reply_to:)
    @content = content
    user_attachements.each do |attachment|
      attachments[attachment.original_filename] = attachment.read
    end
    mail(
      to: to,
      subject: subject,
      reply_to: reply_to
    )
  end

  def creneau_unavailable(organisation:, grouped_invitation_params_by_category:)
    return if organisation.email.blank?

    @organisation = organisation
    @grouped_invitation_params_by_category = grouped_invitation_params_by_category
    mail(
      to: organisation.email,
      subject: "[Alerte créneaux] Vérifier qu'il y a suffisamment de créneaux" \
               " de libre relativement au stock d'invitations en cours",
      reply_to: "rdv-insertion@beta.gouv.fr"
    )
  end

  def notify_rdv_changes(to:, organisation:, participation:, event:)
    @organisation = organisation
    @participation = participation
    @motif_category = participation.follow_up.motif_category
    @event = event

    translated_event = if event == "updated"
                         "modifié"
                       elsif event == "cancelled"
                         "annulé"
                       else
                         "créé"
                       end

    mail(
      to:,
      subject: "[Notification de RDV] Un rendez-vous a été #{translated_event}",
      reply_to: "rdv-insertion@beta.gouv.fr"
    )
  end

  def notify_out_of_slots(organisation:, recipient:, grouped_invitation_params:)
    @organisation = organisation
    @grouped_invitation_params = grouped_invitation_params
    mail(
      to: recipient,
      subject: "[Alerte créneaux] Vérifier qu'il y a suffisamment de créneaux" \
               " de libre relativement au stock d'invitations en cours",
      reply_to: "rdv-insertion@beta.gouv.fr"
    )
  end
end
