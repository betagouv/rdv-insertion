# rubocop:disable Metrics/ModuleLength

module UsersHelper
  def show_convocation?(configuration)
    configuration.convene_user?
  end

  def show_invitations?(configuration)
    configuration.invitation_formats.present?
  end

  def no_search_results?(users)
    users.empty? && params[:search_query].present?
  end

  def display_back_to_list_button? # rubocop:disable Metrics/AbcSize
    [
      params[:search_query], params[:status], params[:action_required], params[:first_invitation_date_before],
      params[:last_invitation_date_before], params[:first_invitation_date_after], params[:last_invitation_date_after],
      params[:referent_id], params[:creation_date_after], params[:creation_date_before], params[:tag_ids]
    ].any?(&:present?)
  end

  def options_for_select_status(statuses_count)
    ordered_statuses_count(statuses_count).map do |status, count|
      next if count.nil?

      ["#{I18n.t("activerecord.attributes.follow_up.statuses.#{status}")} (#{count})", status]
    end.compact
  end

  def ordered_statuses_count(statuses_count)
    [
      ["not_invited", statuses_count["not_invited"]],
      ["invitation_pending", statuses_count["invitation_pending"]],
      ["rdv_pending", statuses_count["rdv_pending"]],
      ["rdv_needs_status_update", statuses_count["rdv_needs_status_update"]],
      ["rdv_excused", statuses_count["rdv_excused"]],
      ["rdv_revoked", statuses_count["rdv_revoked"]],
      ["multiple_rdvs_cancelled", statuses_count["multiple_rdvs_cancelled"]],
      ["rdv_noshow", statuses_count["rdv_noshow"]],
      ["rdv_seen", statuses_count["rdv_seen"]],
      ["closed", statuses_count["closed"]]
    ]
  end

  def background_class_for_follow_up_status(follow_up, number_of_days_before_action_required)
    return "" if follow_up.nil?

    if follow_up.action_required_status?
      "bg-danger border-danger"
    elsif number_of_days_before_action_required &&
          follow_up.time_to_accept_invitation_exceeded?(number_of_days_before_action_required)
      "bg-warning border-warning"
    elsif follow_up.rdv_seen? || follow_up.closed?
      "bg-success border-success"
    else
      ""
    end
  end

  def badge_background_class(follow_up, number_of_days_before_action_required)
    return "blue-out border border-blue" if follow_up.nil?

    if follow_up.action_required_status?
      "bg-danger border-danger"
    elsif number_of_days_before_action_required &&
          follow_up.time_to_accept_invitation_exceeded?(number_of_days_before_action_required)
      "bg-warning border-warning"
    elsif follow_up.rdv_seen? || follow_up.closed?
      "bg-success border-success"
    else
      "blue-out border border-blue"
    end
  end

  def background_class_for_participation_status(participation)
    return "" if participation.follow_up.closed?

    if participation.seen?
      "bg-success border-success"
    elsif participation.cancelled?
      "bg-danger border-danger"
    elsif participation.needs_status_update?
      "bg-warning border-warning"
    else
      ""
    end
  end

  def text_class_for_participation_status(status)
    return "text-success" if status == "seen"
    return "text-light" if status == "unknown"

    "text-danger"
  end

  def human_available_status(participation, status)
    return I18n.t("activerecord.attributes.rdv.statuses.#{status}") unless status == "unknown"

    participation.human_status
  end

  def human_available_detailed_status(participation, status)
    return I18n.t("activerecord.attributes.rdv.statuses.detailed.#{status}") unless status == "unknown"

    temporal_unknown_status = participation.in_the_future? ? "pending" : "needs_status_update"
    I18n.t("activerecord.attributes.rdv.unknown_statuses.detailed.#{temporal_unknown_status}")
  end

  def display_follow_up_status(follow_up, number_of_days_before_action_required)
    return "Non rattaché" if follow_up.nil?

    I18n.t("activerecord.attributes.follow_up.statuses.#{follow_up.status}") +
      display_follow_up_status_notice(follow_up, number_of_days_before_action_required)
  end

  def display_follow_up_status_notice(follow_up, number_of_days_before_action_required)
    return if follow_up.nil?

    if number_of_days_before_action_required &&
       follow_up.time_to_accept_invitation_exceeded?(number_of_days_before_action_required)
      " (Délai dépassé)"
    else
      ""
    end
  end

  def display_convocation_formats(convocation_formats)
    if convocation_formats.empty?
      "❌#{content_tag(:br)}SMS et Email non envoyés#{content_tag(:br)}❌"
    else
      convocation_formats.map { |format| format == "sms" ? "SMS 📱" : "Email 📧" }.join("\n")
    end
  end

  def archived_scope?(scope)
    scope == "archived"
  end

  def rdv_solidarites_agent_searches_url(
    rdv_solidarites_organisation_id, rdv_solidarites_user_id, rdv_solidarites_motif_id, rdv_solidarites_service_id
  )
    params = {
      user_ids: [rdv_solidarites_user_id],
      motif_id: rdv_solidarites_motif_id,
      service_id: rdv_solidarites_service_id,
      commit: "Afficher les créneaux"
    }
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/#{rdv_solidarites_organisation_id}/" \
      "agent_searches?#{params.to_query}"
  end

  def should_convene_for?(follow_up, configuration)
    return false unless configuration.convene_user?

    follow_up.convocable_status? ||
      follow_up.time_to_accept_invitation_exceeded?(configuration.number_of_days_before_action_required)
  end

  def show_parcours?(department)
    department.number.in?(ENV["DEPARTMENTS_WHERE_PARCOURS_ENABLED"].split(","))
  end
end

# rubocop:enable Metrics/ModuleLength
