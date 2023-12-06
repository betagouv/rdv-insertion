module Stats
  module Counters
    class NumberOfConvocationsNoShow
      include Counter

      count every: :update_participation,
            if: -> { participation.previous_changes[:status].present? },
            where_async: -> { participation.notified? },
            decrement_if: -> { participation.status != "noshow" }
    end
  end
end
