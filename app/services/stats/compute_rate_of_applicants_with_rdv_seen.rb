module Stats
  class ComputeRateOfApplicantsWithRdvSeen < BaseService
    def initialize(rdv_contexts:)
      @rdv_contexts = rdv_contexts
    end

    def call
      result.value = compute_rate_of_applicants_with_rdv_seen
    end

    private

    def compute_rate_of_applicants_with_rdv_seen
      (applicants_with_rdv_seen.count / (
        applicants.count.nonzero? || 1
      ).to_f) * 100
    end

    def applicants
      @applicants ||= Applicant.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts).distinct
    end

    def applicants_with_rdv_seen
      @applicants_with_rdv_seen ||= Applicant.joins(:rdv_contexts).where(rdv_contexts: @rdv_contexts.rdv_seen).distinct
    end
  end
end