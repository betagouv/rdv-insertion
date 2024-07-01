module Stats
  module MonthlyStats
    class UpsertStat < BaseService
      def initialize(structure_type:, structure_id:, until_date_string:)
        @structure_type = structure_type
        @structure_id = structure_id
        @until_date_string = until_date_string
      end

      def call
        assign_monthly_stats_attributes_to_stat_record
        save_record!(stat)
      end

      private

      def stat
        @stat ||= Stat.find_or_initialize_by(statable_type: @structure_type, statable_id: @structure_id)
      end

      def assign_monthly_stats_attributes_to_stat_record
        @date = stat.statable&.created_at || DateTime.parse("01/01/2022")

        # We first reinitialize the monthly stats
        stat.attributes.keys.select { |key| key.end_with?("month") }
            .each { |attribute_name| stat[attribute_name] = {} }

        while @date < @until_date_string.to_date
          compute_monthly_stats

          @date += 1.month
        end
      end

      def compute_monthly_stats
        compute_monthly_stats_for_focused_month.stats_values.each do |stat_name, stat_value|
          stat_attribute = stat[stat_name]

          # We don't want to start the hash until we have a value
          next if stat_attribute == {} && stat_value.zero?

          stat_attribute.merge!({ @date.strftime("%m/%Y") => stat_value })
        end
      end

      def compute_monthly_stats_for_focused_month
        Stats::MonthlyStats::ComputeForFocusedMonth.call(
          stat: stat,
          date: @date
        )
      end
    end
  end
end
