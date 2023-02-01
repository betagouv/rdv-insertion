module Stats
  module MonthlyStats
    class UpsertStat < BaseService
      def initialize(department_number:, date_string:)
        @department_number = department_number
        @date_string = date_string
      end

      def call
        merge_monthly_stats_attributes_for_focused_month_to_stat_record
        save_record!(stat)
      end

      private

      def stat
        @stat ||= Stat.find_or_initialize_by(department_number: @department_number)
      end

      def merge_monthly_stats_attributes_for_focused_month_to_stat_record
        compute_monthly_stats_for_focused_month.data.each do |stat_for_focused_month|
          stat_name = stat_for_focused_month[0]
          stat_value = stat_for_focused_month[1]
          stat[stat_name] = stat[stat_name].merge(stat_value)
        end
      end

      def compute_monthly_stats_for_focused_month
        @compute_monthly_stats_for_focused_month ||= Stats::MonthlyStats::ComputeForFocusedMonth.call(
          department_number: @department_number,
          date: @date_string.to_date
        )
      end
    end
  end
end
