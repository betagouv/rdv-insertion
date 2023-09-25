describe Stats::ComputeRateOfApplicantsWithRdvSeen, type: :service do
  subject { described_class.call(rdv_contexts: rdv_contexts) }

  let!(:rdv_contexts) { RdvContext.where(id: [rdv_context1, rdv_context2, rdv_context3, rdv_context4]) }

  let!(:applicant1) { create(:applicant) }
  let!(:rdv_context1) { create(:rdv_context, applicant: applicant1, status: "rdv_seen") }
  let!(:rdv1) { create(:rdv, status: "seen") }
  let!(:participation1) { create(:participation, rdv: rdv1, rdv_context: rdv_context1, status: "seen") }

  let!(:applicant2) { create(:applicant) }
  let!(:rdv_context2) { create(:rdv_context, applicant: applicant2, status: "rdv_pending") }
  let!(:rdv2) { create(:rdv, status: "unknown") }
  let!(:participation2) { create(:participation, rdv: rdv2, rdv_context: rdv_context2, status: "unknown") }

  let!(:applicant3) { create(:applicant) }
  let!(:rdv_context3) { create(:rdv_context, applicant: applicant3, status: "rdv_noshow") }
  let!(:rdv3) { create(:rdv, status: "noshow") }
  let!(:participation3) { create(:participation, rdv: rdv3, rdv_context: rdv_context3, status: "noshow") }

  let!(:applicant4) { create(:applicant) }
  let!(:rdv_context4) { create(:rdv_context, applicant: applicant4, status: "not_invited") }

  describe "#call" do
    let!(:result) { subject }

    it "is a success" do
      expect(result.success?).to eq(true)
    end

    it "renders a float" do
      expect(result.value).to be_a(Float)
    end

    it "computes the percentage of applicants with rdv seen" do
      expect(result.value).to eq(25)
    end
  end
end
