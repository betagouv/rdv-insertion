describe Rdv do
  describe "rdv rdv_solidarites_rdv_id uniqueness validation" do
    context "no collision" do
      let(:rdv) { build(:rdv, rdv_solidarites_rdv_id: 1) }

      it { expect(rdv).to be_valid }
    end

    context "colliding rdv_solidarites_rdv_id" do
      let!(:rdv_existing) { create(:rdv, rdv_solidarites_rdv_id: 1) }
      let(:rdv) { build(:rdv, rdv_solidarites_rdv_id: 1) }

      it "adds errors" do
        expect(rdv).not_to be_valid
        expect(rdv.errors.details).to eq({ rdv_solidarites_rdv_id: [{ error: :taken, value: 1 }] })
        expect(rdv.errors.full_messages.to_sentence)
          .to include("Rdv solidarites rdv est déjà utilisé")
      end
    end
  end

  describe "#notify_users" do
    subject { rdv.save }

    let!(:participation) { create(:participation, convocable: true) }

    context "when the lieu is updated" do
      let!(:rdv) do
        create(:rdv, participations: [participation], address: "some place", starts_at: 2.days.from_now)
      end

      it "enqueues a job to notify rdv users" do
        rdv.address = "some other place"
        expect(NotifyParticipationsJob).to receive(:perform_async)
          .with([participation.id], :updated)
        subject
      end

      context "when the rdv is not convocable" do
        before { participation.update! convocable: false }

        it "does not enqueue a notify users job" do
          rdv.address = "some other place"
          expect(NotifyParticipationsJob).not_to receive(:perform_async)
          subject
        end
      end
    end

    context "when the start time is updated" do
      let!(:rdv) { create(:rdv, participations: [participation], starts_at: 2.days.from_now) }

      it "enqueues a job to notify rdv users" do
        rdv.starts_at = 3.days.from_now
        expect(NotifyParticipationsJob).to receive(:perform_async)
          .with([participation.id], :updated)
        subject
      end

      context "when the rdv is not convocable" do
        before { participation.update! convocable: false }

        it "does not enqueue a notify users job" do
          rdv.starts_at = 3.days.from_now
          expect(NotifyParticipationsJob).not_to receive(:perform_async)
          subject
        end
      end
    end

    context "when the rdv is in the past" do
      let!(:rdv) { create(:rdv, participations: [participation], starts_at: 2.days.ago) }

      it "does not enqueue a job to notify rdv users" do
        expect(NotifyParticipationsJob).not_to receive(:perform_async)
        subject
      end
    end

    context "when the another attribute is updated" do
      let!(:rdv) { create(:rdv, participations: [participation], duration_in_min: 30) }

      it "does not enqueue a notify users job" do
        rdv.duration_in_min = 45
        expect(NotifyParticipationJob).not_to receive(:perform_async)
        subject
      end
    end
  end

  describe "nested participation creation" do
    let!(:user) { create(:user) }
    let!(:follow_up) { create(:follow_up) }

    context "when id is nil and participation does not exist" do
      let!(:rdv_count_before) { described_class.count }
      let!(:participation_count_before) { Participation.count }
      let!(:participation_attributes) do
        {
          id: nil, user: user, follow_up: follow_up,
          created_by: "agent", rdv_solidarites_participation_id: 17
        }
      end
      let!(:rdv) { create(:rdv, participations_attributes: participation_attributes) }

      it "creates a rdv and a participation" do
        expect(described_class.count).to eq(rdv_count_before + 1)
        expect(Participation.count).to eq(participation_count_before + 1)
      end
    end

    context "when id is nil and participation already exist" do
      let!(:rdv) do
        create(:rdv, participations: [create(:participation, rdv_solidarites_participation_id: 18)])
      end
      let!(:participation_attributes) do
        {
          id: nil, user: user, follow_up: follow_up,
          created_by: "agent", rdv_solidarites_participation_id: 18
        }
      end
      let!(:rdv_count_before) { described_class.count }
      let!(:participation_count_before) { Participation.count }

      before do
        rdv.update!(status: "seen", participations_attributes: participation_attributes)
      end

      it "updates the rdv but no dot creates a participation" do
        expect(rdv.reload.status).to eq("seen")
        expect(Participation.count).to eq(participation_count_before)
      end
    end

    context "when participation id is present" do
      let!(:rdv) { create(:rdv) }
      let!(:participation) { rdv.participations.first }
      let!(:participation_attributes) { { id: participation.id, created_by: "agent" } }
      let!(:participation_count_before) { Participation.count }

      before do
        rdv.reload.update!({ participations_attributes: participation_attributes })
      end

      it "updates the existing participation" do
        expect(Participation.count).to eq(participation_count_before)
        expect(participation.reload.created_by).to eq("agent")
      end
    end

    context "when participation id is present & destroy attributes is set to true" do
      let!(:rdv) { create(:rdv) }
      let!(:participation) { rdv.participations.first }
      let!(:participation_attributes) { { id: participation.id, _destroy: true } }
      let!(:participation_count_before) { Participation.count }

      before do
        rdv.reload.update!({ participations_attributes: participation_attributes })
      end

      it "destroys the existing participation" do
        expect(Participation.count).to eq(participation_count_before - 1)
      end
    end
  end
end
