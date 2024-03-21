module Stats
  class ComputeAverageTimeBetweenInvitationAndRdvInDays < BaseService
    def initialize(follow_ups:)
      @follow_ups = follow_ups
    end

    def call
      result.value = compute_average_time_between_invitation_and_rdv_in_days
    end

    private

    # Delays between the first invitation and the first rdv
    def compute_average_time_between_invitation_and_rdv_in_days
      invitation_delays = []

      @follow_ups.find_each do |follow_up|
        # Some follow_ups might have negative values when users have had
        # rdvs on Rdv-Solidarités prior to being imported in the app.
        # We don't want to take those values into account.
        next if follow_up.time_between_invitation_and_rdv_in_days.negative?

        invitation_delays << follow_up.time_between_invitation_and_rdv_in_days
      end

      return 0.0 if invitation_delays.empty?

      invitation_delays.sum / invitation_delays.size.to_f
    end
  end
end
