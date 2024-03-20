module Stats
  module GlobalStats
    class UpsertStatJob < ApplicationJob
      sidekiq_options retry: 1

      def perform(structure_type, structure_id)
        # to do : add timeout as a global concern for all jobs and remove it here
        Timeout.timeout(60.minutes) do
          call_service!(
            Stats::GlobalStats::UpsertStat,
            structure_type: structure_type, structure_id: structure_id
          )
        end
      end
    end
  end
end
