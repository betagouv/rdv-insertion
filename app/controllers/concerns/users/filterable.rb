# rubocop:disable Metrics/ModuleLength

module Users::Filterable
  private

  def filter_users
    filter_users_by_search_query
    filter_users_by_action_required
    filter_users_by_referent
    filter_users_by_status
    filter_users_by_creation_date_after
    filter_users_by_creation_date_before
    filter_users_by_first_invitations
    filter_users_by_last_invitations
    filter_users_by_page
    filter_users_by_tags
  end

  def filter_users_by_tags
    return if params[:tag_ids].blank?

    user_ids = TagUser
               .select(:user_id)
               .where(tag_id: params[:tag_ids])
               .group(:user_id)
               .having("COUNT(DISTINCT tag_id) = ?", [params[:tag_ids]].flatten.count)
               .pluck(:user_id)

    @users = @users.where(id: user_ids)
  end

  def filter_users_by_status
    return if params[:status].blank?

    @users = @users.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.status(params[:status]))
  end

  def filter_users_by_action_required
    return unless params[:action_required] == "true"

    @users = @users.joins(:rdv_contexts).where(
      rdv_contexts: @rdv_contexts.action_required(@current_category_configuration.number_of_days_before_action_required)
    )
  end

  def filter_users_by_referent
    return if params[:referent_id].blank?

    @users = @users.joins(:referents).where(referents: { id: params[:referent_id] })
  end

  def filter_users_by_search_query
    return if params[:search_query].blank?

    # reorder is necessary to use distinct and ordering https://github.com/Casecommons/pg_search/issues/238#issuecomment-543702501
    @users = @users.search_by_text(params[:search_query]).reorder("")
  end

  def filter_users_by_page
    return if request.format == "csv"

    @users = @users.page(page)
  end

  def filter_users_by_creation_date_after
    return if params[:creation_date_after].blank?

    @users = @users.where("users.created_at > ?", params[:creation_date_after].to_date.end_of_day)
  end

  def filter_users_by_creation_date_before
    return if params[:creation_date_before].blank?

    @users = @users.where("users.created_at < ?", params[:creation_date_before].to_date.end_of_day)
  end

  def filter_users_by_first_invitations
    return if [first_invitation_date_before, first_invitation_date_after].all?(&:blank?)

    relevant_invitations = invitations_belonging_to_rdv_contexts(users_first_invitations, @rdv_contexts)
    filter_users_by_invitation_dates(
      relevant_invitations, first_invitation_date_before, first_invitation_date_after
    )
  end

  def filter_users_by_last_invitations
    return if [last_invitation_date_before, last_invitation_date_after].all?(&:blank?)

    relevant_invitations = invitations_belonging_to_rdv_contexts(users_last_invitations, @rdv_contexts)
    filter_users_by_invitation_dates(
      relevant_invitations, last_invitation_date_before, last_invitation_date_after
    )
  end

  def filter_users_by_invitation_dates(invitations, invitation_date_before, invitation_date_after)
    filtered_invitations = invitations.select do |invitation|
      (invitation_date_before.blank? || invitation.sent_before?(invitation_date_before.to_date.end_of_day)) &&
        (invitation_date_after.blank? || invitation.sent_after?(invitation_date_after.to_date.beginning_of_day))
    end
    @users = @users.where(id: filtered_invitations.pluck(:user_id))
  end

  def first_invitation_date_before
    params[:first_invitation_date_before]
  end

  def first_invitation_date_after
    params[:first_invitation_date_after]
  end

  def last_invitation_date_before
    params[:last_invitation_date_before]
  end

  def last_invitation_date_after
    params[:last_invitation_date_after]
  end

  def users_first_invitations
    @users_first_invitations ||= Invitation.joins(:user)
                                           .where(user_id: @users.ids)
                                           .order("invitations.created_at ASC")
                                           .group_by(&:user_id)
                                           .transform_values(&:first)
                                           .values
  end

  def users_last_invitations
    @users_last_invitations ||= Invitation.joins(:user)
                                          .where(user_id: @users.ids)
                                          .order("invitations.created_at DESC")
                                          .group_by(&:user_id)
                                          .transform_values(&:first)
                                          .values
  end

  def invitations_belonging_to_rdv_contexts(invitations, rdv_contexts)
    if rdv_contexts.blank?
      invitations
    else
      invitation_ids = invitations.pluck(:id)
      rdv_context_ids = rdv_contexts.pluck(:id)
      Invitation.where(id: invitation_ids, rdv_context_id: rdv_context_ids)
    end
  end
end

# rubocop:enable Metrics/ModuleLength
