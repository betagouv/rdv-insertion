module Stats
  module MonthlyStats
    class UpsertStatsJob < ApplicationJob
      sidekiq_options queue: :stats

      def perform
        Stats::MonthlyStats::UpsertStatJob.perform_async("Department", nil, Time.zone.now)

        Department.find_each do |department|
          Stats::MonthlyStats::UpsertStatJob.perform_async("Department", department.id, Time.zone.now)
        end

        Organisation.find_each do |organisation|
          Stats::MonthlyStats::UpsertStatJob.perform_async("Organisation", organisation.id, Time.zone.now)
        end
      end
    end
  end
end
