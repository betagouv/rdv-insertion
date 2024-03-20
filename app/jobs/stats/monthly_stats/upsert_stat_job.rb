module Stats
  module MonthlyStats
    class UpsertStatJob < ApplicationJob
      sidekiq_options retry: 1

      def perform(structure_type, structure_id, until_date_string)
        # to do : add timeout as a global concern for all jobs and remove it here
        Timeout.timeout(60.minutes) do
          call_service!(
            Stats::MonthlyStats::UpsertStat,
            structure_type: structure_type, structure_id: structure_id, until_date_string: until_date_string
          )
        end
      end
    end
  end
end
