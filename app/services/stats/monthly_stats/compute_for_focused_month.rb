module Stats
  module MonthlyStats
    class ComputeForFocusedMonth < BaseService
      def initialize(stat:, date:)
        @stat = stat
        @date = date
      end

      def call
        result.stats_values = stats_for_focused_month
      end

      private

      def stats_for_focused_month
        @stats_for_focused_month ||= {
          users_count_grouped_by_month: users_count_for_focused_month,
          users_with_rdv_count_grouped_by_month: users_with_rdv_count_grouped_by_month,
          rdvs_count_grouped_by_month: rdvs_count_for_focused_month,
          sent_invitations_count_grouped_by_month: sent_invitations_count_for_focused_month,
          rate_of_no_show_for_invitations_grouped_by_month: rate_of_no_show_for_invitations_for_focused_month,
          rate_of_no_show_for_convocations_grouped_by_month: rate_of_no_show_for_notifications_for_focused_month,
          average_time_between_invitation_and_rdv_in_days_by_month:
            average_time_between_invitation_and_rdv_in_days_for_focused_month,
          rate_of_users_oriented_in_less_than_30_days_by_month:
            rate_of_users_oriented_in_less_than_30_days_for_focused_month,
          rate_of_users_oriented_in_less_than_15_days_by_month:
            rate_of_users_oriented_in_less_than_15_days_for_focused_month,
          rate_of_users_oriented_grouped_by_month: rate_of_users_oriented_for_focused_month,
          rate_of_autonomous_users_grouped_by_month:
            rate_of_autonomous_users_for_focused_month
        }
      end

      def users_count_for_focused_month
        created_during_focused_month(@stat.all_users).count
      end

      def users_with_rdv_count_grouped_by_month
        created_during_focused_month(@stat.user_ids_with_rdv_set).count
      end

      def rdvs_count_for_focused_month
        created_during_focused_month(@stat.all_participations).count
      end

      def sent_invitations_count_for_focused_month
        created_during_focused_month(@stat.invitations_set).count
      end

      def rate_of_no_show_for_invitations_for_focused_month
        ComputeRateOfNoShow.call(
          participations: created_during_focused_month(@stat.participations_after_invitations_set)
        ).value.round
      end

      def rate_of_no_show_for_notifications_for_focused_month
        ComputeRateOfNoShow.call(
          participations: created_during_focused_month(@stat.participations_with_notifications_set)
        ).value.round
      end

      def average_time_between_invitation_and_rdv_in_days_for_focused_month
        ComputeAverageTimeBetweenInvitationAndRdvInDays.call(
          structure: @stat.statable,
          range: @date.all_month
        ).value.round
      end

      def rate_of_users_oriented_in_less_than_30_days_for_focused_month
        ComputeRateOfRdvSeenInLessThanNDays.call(
          follow_ups: created_during_focused_month(@stat.users_first_orientation_follow_up),
          number_of_days: 30
        ).value.round
      end

      def rate_of_users_oriented_in_less_than_15_days_for_focused_month
        ComputeRateOfRdvSeenInLessThanNDays.call(
          follow_ups: created_during_focused_month(@stat.users_first_orientation_follow_up),
          number_of_days: 15
        ).value.round
      end

      def rate_of_users_oriented_for_focused_month
        ComputeRateOfUsersWithRdvSeen.call(
          follow_ups: created_during_focused_month(@stat.orientation_follow_ups_with_invitations)
        ).value.round
      end

      def rate_of_autonomous_users_for_focused_month
        ComputeRateOfAutonomousUsers.call(
          users: created_during_focused_month(@stat.invited_users_set)
        ).value.round
      end

      def created_during_focused_month(data)
        data.where(created_at: @date.all_month)
      end
    end
  end
end
