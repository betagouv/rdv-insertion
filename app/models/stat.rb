class Stat < ApplicationRecord
  GLOBAL_STAT_ATTRIBUTES = %w[
    users_count
    users_with_rdv_count
    rdvs_count
    sent_invitations_count
    rate_of_no_show_for_invitations
    rate_of_no_show_for_convocations
    average_time_between_invitation_and_rdv_in_days
    rate_of_users_oriented_in_less_than_30_days
    rate_of_users_oriented_in_less_than_15_days
    rate_of_users_oriented
    rate_of_autonomous_users
    agents_count
  ].freeze

  MONTHLY_STAT_ATTRIBUTES = %w[
    users_count_grouped_by_month
    users_with_rdv_count_grouped_by_month
    rdvs_count_grouped_by_month
    sent_invitations_count_grouped_by_month
    rate_of_no_show_for_invitations_grouped_by_month
    rate_of_no_show_for_convocations_grouped_by_month
    average_time_between_invitation_and_rdv_in_days_by_month
    rate_of_users_oriented_in_less_than_30_days_by_month
    rate_of_users_oriented_in_less_than_15_days_by_month
    rate_of_users_oriented_grouped_by_month
    rate_of_autonomous_users_grouped_by_month
  ].freeze

  belongs_to :statable, polymorphic: true, optional: true

  def all_users
    @all_users ||= statable.nil? ? User.all : statable.users
  end

  def all_participations
    statable.nil? ? Participation.all : statable.participations
  end

  def invitations_set
    @invitations_set ||= statable.nil? ? Invitation.all : statable.invitations
  end

  # We filter the participations to only keep the participations of the users in the scope
  def participations_set
    participations = all_participations
                     .joins(:user)
                     .where(users: { deleted_at: nil })

    if statable.present?
      participations = participations.joins(user: :organisations)
                                     .where(users: { organisations: all_organisations })
    end

    participations
  end

  def user_ids_with_rdv_set
    participations_set.where(status: %w[seen unknown])
                      .select(:user_id)
                      .distinct
  end

  # We filter participations to keep only convocations
  def participations_with_notifications_set
    participations_set.joins(:notifications).select("participations.id, participations.status").distinct
  end

  # We filter participations to keep only invitations
  def participations_after_invitations_set
    participations_set.where.missing(:notifications)
                      .joins(:follow_up_invitations)
                      .select("participations.id, participations.status")
                      .distinct
  end

  # We exclude the rdvs collectifs motifs to correctly compute the rate of autonomous users
  def rdvs_non_collectifs_set
    Rdv.where(motif: Motif.individuel).distinct
  end

  def invited_users_set
    @invited_users_set ||= users_set.with_sent_invitations.distinct
  end

  # We filter the users by organisations and withdraw deleted users
  def users_set
    users = User.active.preload(:participations)
    users = users.joins(:organisations).where(organisations: all_organisations) if statable.present?

    users.distinct
  end

  # We don't include in the stats the agents working for rdv-insertion
  def agents_set
    @agents_set ||= Agent.not_betagouv
                         .joins(:organisations)
                         .where(organisations: all_organisations)
                         .where.not(last_sign_in_at: nil)
                         .distinct
  end

  def all_organisations
    @all_organisations ||= if statable_type == "Organisation"
                             Organisation.where(id: statable_id)
                           else
                             statable.nil? ? Organisation.all : statable.organisations
                           end
  end

  # To compute the rate of users oriented, we only consider the users who have been invited
  # because the users that are directly convocated do not benefit from our added value
  def orientation_follow_ups_with_invitations
    FollowUp.orientation.preload(:participations, :invitations)
            .where(user: users_set)
            .with_sent_invitations
            .distinct
  end

  def users_first_orientation_follow_up
    # we consider minimum(:id) being the same as minimum(:created_at) as the id increases with created_at
    FollowUp.where(user: users_set)
            .where(id: FollowUp.orientation.group(:user_id).minimum(:id).values)
            .preload(participations: :rdv)
            .distinct
  end
end
