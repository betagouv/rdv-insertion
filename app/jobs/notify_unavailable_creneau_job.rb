class NotifyUnavailableCreneauJob < ApplicationJob
  def perform(organisation_id)
    result =
      Invitations::VerifyOrganisationCreneauxAvailability.call(organisation_id: organisation_id)
    return if result.grouped_invitation_params_by_category.empty?

    # grouped_invitation_params_by_category = [{
    #   motif_category_name: "RSA Orientation",
    #   city_code: ["75001", "75002", "75003"],
    #   referent_ids: ["1", "2", "3"]
    # },...]
    organisation = Organisation.find(organisation_id)
    deliver_general_email(organisation, result.grouped_invitation_params_by_category)
    deliver_per_category_notify_out_of_slots_email(organisation, result.grouped_invitation_params_by_category)
    notify_on_mattermost(organisation, result.grouped_invitation_params_by_category)
  end

  private

  def deliver_general_email(organisation, grouped_invitation_params_by_category)
    OrganisationMailer.creneau_unavailable(
      organisation: organisation,
      grouped_invitation_params_by_category: grouped_invitation_params_by_category
    ).deliver_now
  end

  def deliver_per_category_notify_out_of_slots_email(organisation, grouped_invitation_params_by_category)
    grouped_invitation_params_by_category.each do |grouped_invitation_params|
      next unless grouped_invitation_params[:matching_category_configuration]&.notify_out_of_slots?

      OrganisationMailer.notify_out_of_slots(
        organisation: organisation,
        recipient: grouped_invitation_params[:matching_category_configuration].notify_out_of_slots_email,
        grouped_invitation_params_by_category: grouped_invitation_params_by_category
      ).deliver_now
    end
  end

  def notify_on_mattermost(organisation, grouped_invitation_params_by_category)
    grouped_invitation_params_by_category.each do |grouped_invitation_params|
      MattermostClient.send_to_notif_channel(formated_string_for_mattermost_message(organisation,
                                                                                    grouped_invitation_params))
    end
  end

  def formated_string_for_mattermost_message(organisation, grouped_invitation_params)
    string =
      "Créneaux indisponibles pour l'organisation #{organisation.name}" \
      " (Département: #{organisation.department.name})\n" \
      " Motif : #{grouped_invitation_params[:motif_category_name]}\n" \
      " Nombre d'invitations concernées : #{grouped_invitation_params[:invitations_counter]}\n"

    if grouped_invitation_params[:zip_codes].present?
      string += " Codes postaux : #{grouped_invitation_params[:zip_codes].join(', ')}\n"
    end

    if grouped_invitation_params[:referent_ids].present?
      string += " Référents (rdvsp_ids) : #{grouped_invitation_params[:referent_ids].join(', ')}\n"
    end

    string += " ** L'organisation n'a pas d'email configuré et n'a pas été notifiée !**\n" if organisation.email.blank?

    string
  end
end
