module Stats
  module GlobalStats
    class UpsertStatJob < ApplicationJob
      sidekiq_options queue: :stats, retry: 3

      def perform(structure_type, structure_id, stat_name)
        Timeout.timeout(30.minutes) do
          stat = Stat.find_or_initialize_by(statable_type: structure_type, statable_id: structure_id)
          result = Stats::GlobalStats::Compute.new(stat:).send(stat_name)

          stat.update!(stat_name => result)
        end
      end
    end
  end
end
