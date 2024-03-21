module Stats
  class ComputeRateOfRdvSeenInLessThanNDays < BaseService
    def initialize(follow_ups:, number_of_days:)
      @follow_ups = follow_ups
      @number_of_days = number_of_days
    end

    def call
      result.value = compute_rate_of_follow_ups_with_rdv_seen_in_less_than_n_days
    end

    private

    # Rate of follow_ups with rdv seen in less than n days
    def compute_rate_of_follow_ups_with_rdv_seen_in_less_than_n_days
      (follow_ups_with_rdv_seen_in_less_than_n_days.count / (
        follow_ups_created_more_than_n_days_ago.count.nonzero? || 1
      ).to_f) * 100
    end

    def follow_ups_with_rdv_seen_in_less_than_n_days
      @follow_ups_with_rdv_seen_in_less_than_n_days ||= begin
        follow_ups = []

        follow_ups_with_rdvs_seen_created_more_than_n_days_ago.find_in_batches(batch_size: 1000) do |batch|
          follow_ups += batch.select { |record| record.rdv_seen_delay_in_days < @number_of_days }
        end

        follow_ups
      end
    end

    def follow_ups_with_rdvs_seen_created_more_than_n_days_ago
      @follow_ups_with_rdvs_seen_created_more_than_n_days_ago ||=
        # we load the ids of follow_ups_created_more_than_n_days_ago to simplify the request
        # that is triggered in each batch in the find_in_batches block above
        FollowUp.where(id: follow_ups_created_more_than_n_days_ago)
                .joins(:participations)
                .where(participations: { status: "seen" })
                .distinct
    end

    def follow_ups_created_more_than_n_days_ago
      @follow_ups_created_more_than_n_days_ago ||= @follow_ups.where("follow_ups.created_at < ?",
                                                                     @number_of_days.days.ago).to_a
    end
  end
end
