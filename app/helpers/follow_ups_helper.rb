module FollowUpsHelper
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

  def should_convene_for?(follow_up, configuration)
    return false unless configuration.convene_user?

    follow_up.convocable_status? ||
      follow_up.time_to_accept_invitation_exceeded?(configuration.number_of_days_before_action_required)
  end

  def sms_invitation_disabled_for?(user, follow_up, department)
    !user.phone_number_is_mobile? || user.archived_in?(department) || follow_up.rdv_pending? || follow_up.closed?
  end

  def email_invitation_disabled_for?(user, follow_up, department)
    !user.email? || user.archived_in?(department) || follow_up.rdv_pending? || follow_up.closed?
  end

  def postal_invitation_disabled_for?(user, follow_up, department)
    !user.address? || user.archived_in?(department) || follow_up.rdv_pending? || follow_up.closed?
  end

  def invitation_dates_by_format(invitations, invitation_formats)
    invitation_dates_by_formats = invitation_formats.index_with { |_invitation_format| [] }
    invitation_dates_by_formats.merge!(
      invitations.group_by(&:format)
                 .select { |format| invitation_formats.include?(format) }
                 .transform_values { |invites| invites.map(&:created_at).sort.reverse }.to_h
    )
    invitation_dates_by_formats
  end

  def max_invitation_dates_for_a_format(invitation_dates_by_formats)
    invitation_dates_by_formats.values.map(&:count).max
  end
end
