module ParticipationsHelper
  def human_new_status(participation, new_status)
    if new_status == "unknown"
      I18n.t("activerecord.attributes.rdv.unknown_statuses.#{temporal_unknown_status(participation)}")
    else
      I18n.t("activerecord.attributes.rdv.statuses.#{new_status}")
    end
  end

  def human_new_status_detailed(participation, new_status)
    if new_status == "unknown"
      I18n.t("activerecord.attributes.rdv.unknown_statuses.detailed.#{temporal_unknown_status(participation)}")
    else
      I18n.t("activerecord.attributes.rdv.statuses.detailed.#{new_status}")
    end
  end

  def could_notify_status_change?(participation, new_status)
    return false if participation.in_the_past?

    (participation.pending? && new_status.in?(Participation::CANCELLED_STATUSES)) ||
      (participation.cancelled? && new_status.in?(Participation::PENDING_STATUSES))
  end

  def text_class_for_participation_status(status)
    return "text-success" if status == "seen"
    return "text-light" if status == "unknown"

    "text-danger"
  end

  def background_class_for_participation_status(participation)
    return "" if participation.rdv_context.closed?

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

  def display_convocation_formats(convocation_formats)
    if convocation_formats.empty?
      "❌#{content_tag(:br)}SMS et Email non envoyés#{content_tag(:br)}❌"
    else
      convocation_formats.map { |format| format == "sms" ? "SMS 📱" : "Email 📧" }.join("\n")
    end
  end

  private

  def temporal_unknown_status(participation)
    participation.in_the_future? ? "pending" : "needs_status_update"
  end
end
