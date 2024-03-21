module FollowUpStatus
  extend ActiveSupport::Concern

  included do
    enum status: {
      not_invited: 0, invitation_pending: 1, rdv_pending: 2,
      rdv_needs_status_update: 3, rdv_noshow: 4, rdv_revoked: 5, rdv_excused: 6,
      rdv_seen: 7, multiple_rdvs_cancelled: 8, closed: 9
    }
    before_save :set_status
  end

  def set_status
    participations.reload
    invitations.reload
    self.status = compute_status
  end

  private

  def compute_status
    return :closed if closed_at.present?

    return :not_invited if invitations.empty? && rdvs.empty?

    invitation_sent_after_last_created_participation? ? :invitation_pending : status_from_participations
  end

  def invitation_sent_after_last_created_participation?
    return false if invitations.empty?
    return true if participations.empty?

    # If there is a pending rdv we compare to the date of the rdv, otherwise to the date of
    # the participation creation
    participation_date_to_compare =
      if last_created_participation.pending?
        last_created_participation.starts_at
      else
        last_created_participation.created_at
      end

    last_invitation_created_at > participation_date_to_compare
  end

  def multiple_cancelled_participations?
    participations.select(&:cancelled_by_user?).length > 1
  end

  def seen_rdv_after_last_created_participation?
    seen_participations.present? &&
      seen_participations.max_by(&:starts_at).starts_at > last_created_participation.created_at
  end

  def status_from_participations
    if participations.any?(&:pending?)
      :rdv_pending
    elsif last_created_participation.seen? || seen_rdv_after_last_created_participation?
      :rdv_seen
    elsif multiple_cancelled_participations?
      :multiple_rdvs_cancelled
    elsif last_created_participation.cancelled?
      :"rdv_#{last_created_participation.status}"
    else
      :rdv_needs_status_update
    end
  end
end
