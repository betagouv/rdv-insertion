module InvitationsHelper
  def show_invitation?(format, invitation_formats)
    invitation_formats.include?(format)
  end

  def sms_invitation_disabled_for?(user, follow_up, user_is_archived)
    !user.phone_number_is_mobile? || user_is_archived || follow_up.rdv_pending? ||
      follow_up.closed?
  end

  def email_invitation_disabled_for?(user, follow_up, user_is_archived)
    !user.email? || user_is_archived || follow_up.rdv_pending? || follow_up.closed?
  end

  def postal_invitation_disabled_for?(user, follow_up, user_is_archived)
    !user.address? || user_is_archived || follow_up.rdv_pending? || follow_up.closed?
  end

  def invitations_by_format(invitations, invitation_formats)
    invitation_formats.index_with { |_invitation_format| [] }.merge!(
      invitations.group_by(&:format)
                 .select { |format| invitation_formats.include?(format) }
                 .transform_values { |invites| invites.sort_by(&:created_at).reverse }
    )
  end

  def max_number_of_invitations_for_a_format(invitations_by_format)
    invitations_by_format.values.map(&:count).max
  end
end
