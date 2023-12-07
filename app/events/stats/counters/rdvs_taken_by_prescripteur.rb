module Stats
  module Counters
    class RdvsTakenByPrescripteur
      include Statisfy::Counter

      count every: :participation_created,
            if: -> { participation.created_by == "prescripteur" },
            uniq_by: -> { participation.user_id }
    end
  end
end
