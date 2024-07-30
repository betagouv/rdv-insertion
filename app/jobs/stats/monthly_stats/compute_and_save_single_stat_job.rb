module Stats
  module MonthlyStats
    class ComputeAndSaveSingleStatJob < ApplicationJob
      sidekiq_options queue: :stats, retry: 3

      def perform(stat_id, attribute_name, date)
        Timeout.timeout(20.minutes) do
          date = date.to_datetime
          stat = Stat.find(stat_id)
          result = Stats::MonthlyStats::ComputeForFocusedMonth.new(stat:, date:).send(attribute_name)

          Stat.transaction do
            stat.reload(lock: true)
            stat.update!(
              attribute_name => (stat.send(attribute_name) || {}).merge({ date.strftime("%m/%Y") => result })
            )
          end
        end
      end
    end
  end
end
