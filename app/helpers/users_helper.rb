module UsersHelper
  def show_convocation?(category_configuration)
    category_configuration.convene_user?
  end

  def show_invitations?(category_configuration)
    category_configuration.invitation_formats.present?
  end

  def no_search_results?(users)
    users.empty? && params[:search_query].present?
  end

  def display_back_to_list_button? # rubocop:disable Metrics/AbcSize
    [
      params[:search_query], params[:status], params[:action_required], params[:first_invitation_date_before],
      params[:last_invitation_date_before], params[:first_invitation_date_after], params[:last_invitation_date_after],
      params[:referent_id], params[:creation_date_after], params[:creation_date_before], params[:tag_ids],
      params[:orientation_type]
    ].any?(&:present?)
  end

  def options_for_select_status(statuses_count)
    ordered_statuses_count(statuses_count).map do |status, count|
      next if count.nil?

      ["#{I18n.t("activerecord.attributes.follow_up.statuses.#{status}")} (#{count})", status]
    end.compact
  end

  def options_for_select_referent(referents)
    referents.map { |agent| [agent, agent.id] }
  end

  def ordered_statuses_count(statuses_count)
    [
      ["not_invited", statuses_count["not_invited"]],
      ["invitation_pending", statuses_count["invitation_pending"]],
      ["rdv_pending", statuses_count["rdv_pending"]],
      ["rdv_needs_status_update", statuses_count["rdv_needs_status_update"]],
      ["rdv_excused", statuses_count["rdv_excused"]],
      ["rdv_revoked", statuses_count["rdv_revoked"]],
      ["rdv_noshow", statuses_count["rdv_noshow"]],
      ["rdv_seen", statuses_count["rdv_seen"]],
      ["closed", statuses_count["closed"]]
    ]
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

  def show_parcours?(department, organisation)
    return policy(department).parcours? if department_level?

    policy(department).parcours? && (organisation.blank? || policy(organisation).parcours?)
  end

  def show_rdv_organisation_selection_for?(user, agent, department)
    mutual_department_organisations(user, agent, department).length > 1
  end

  def mutual_department_organisations(user, agent, department)
    (agent.organisations & user.organisations).select { |o| o.department_id == department.id }
  end

  def current_or_mutual_organisation_id(user, agent, department)
    current_organisation_id || mutual_department_organisations(user, agent, department).first.id
  end

  def show_user_attribute?(user, attribute_name)
    UserPolicy.show_user_attribute?(user:, attribute_name:)
  end

  def assignable_user_attribute?(user, attribute_name)
    assigning_organisation =
      current_organisation || current_agent_department_organisations.max_by do |organisation|
        UserPolicy::RESTRICTED_USER_ATTRIBUTES_BY_ORGANISATION_TYPE[organisation.organisation_type.to_sym].length
      end
    UserPolicy.assignable_user_attribute?(user:, attribute_name:, assigning_organisation:)
  end
end
