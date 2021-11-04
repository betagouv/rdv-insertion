module ApplicantsHelper
  def format_date(date)
    date&.strftime("%d/%m/%Y")
  end

  def show_invitation?(department)
    !department.no_invitation?
  end

  def show_notification?(department)
    department.notify_applicant?
  end

  def display_attribute(attribute)
    attribute || " - "
  end

  def no_search_results?(applicants)
    applicants.empty? && params[:search_query].present?
  end

  def display_back_to_list_button?
    [params[:search_query], params[:status], params[:action_required]].any?(&:present?)
  end

  def options_for_select_status(statuses_count)
    statuses_count.map do |status, count|
      ["#{I18n.t("activerecord.attributes.applicant.statuses.#{status}")} (#{count})", status]
    end
  end

  def background_class_for_status(applicant)
    if applicant.action_required?
      applicant.attention_needed? ? "text-dark-blue bg-warning border-warning" : "bg-danger border-danger"
    elsif applicant.rdv_seen?
      "text-white bg-success border-success"
    else
      ""
    end
  end

  def display_notice(applicant)
    applicant.invited_before_time_window? ? " (Délai dépassé)" : ""
  end

  def rdv_solidarites_user_url(applicant)
    department_id = applicant.department.rdv_solidarites_organisation_id
    "#{ENV['RDV_SOLIDARITES_URL']}/admin/organisations/#{department_id}/users/#{applicant.rdv_solidarites_user_id}"
  end
end
