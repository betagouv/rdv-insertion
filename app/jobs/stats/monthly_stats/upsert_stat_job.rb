module Stats
  module MonthlyStats
    class UpsertStatJob < ApplicationJob
      sidekiq_options queue: :stats

      def perform(structure_type, structure_id, until_date_string)
        @stat = Stat.find_or_initialize_by(statable_type: structure_type, statable_id: structure_id)
        @date = @stat.statable&.created_at || DateTime.parse("01/01/2022")

        while @date < until_date_string.to_date
          compute_monthly_stats

          @date += 1.month
        end
      end

      private

      def compute_monthly_stats
        Stat::MONTHLY_STAT_ATTRIBUTES.each do |method_name|
          Stats::MonthlyStats::ComputeAndSaveSingleStatJob.perform_async(@stat.id, method_name, @date)
        end
      end
    end
  end
end
