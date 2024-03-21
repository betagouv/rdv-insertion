describe UpsertRecord, type: :service do
  context "for a rdv" do
    subject do
      described_class.call(
        klass: klass, rdv_solidarites_attributes: rdv_solidarites_attributes,
        additional_attributes: additional_attributes
      )
    end

    let!(:klass) { Rdv }
    let!(:additional_attributes) do
      {
        participations_attributes: [
          {
            id: nil,
            status: "unknown",
            created_by: created_by,
            user_id: user_id,
            rdv_solidarites_participation_id: 998,
            follow_up_id: follow_up.id
          }
        ],
        lieu_id: lieu.id,
        motif_id: motif.id,
        organisation_id: organisation.id
      }
    end
    let!(:user_id) { 33 }
    let!(:user_ids) { [user_id] }
    let!(:organisation) { create(:organisation) }
    let!(:rdv_solidarites_rdv_id) { 12 }
    let!(:rdv_solidarites_attributes) do
      { id: 12, starts_at: starts_at, duration_in_min: duration_in_min,
        status: status, created_by: created_by }
    end
    let!(:user) { create(:user, id: user_id) }
    let!(:follow_up) { create(:follow_up) }
    let!(:lieu) { create(:lieu) }
    let!(:motif) { create(:motif) }
    let!(:starts_at) { Time.zone.parse("2021-09-08 12:00:00") }
    let!(:duration_in_min) { 45 }
    let!(:status) { "unknown" }
    let!(:created_by) { "user" }

    describe "#call" do
      context "when the record exists" do
        let!(:rdv) { create(:rdv, rdv_solidarites_rdv_id: rdv_solidarites_rdv_id) }

        it "assigns the attributes" do
          subject
          rdv.reload
          expect(rdv.starts_at).to eq(starts_at)
          expect(rdv.duration_in_min).to eq(duration_in_min)
          expect(rdv.status).to eq(status)
          expect(rdv.created_by).to eq("user")
          expect(rdv.user_ids).to include(*user_ids)
          expect(rdv.id).not_to eq(rdv_solidarites_rdv_id)

          # it also creates a participation in this case
          participation = Participation.order(:created_at).last
          expect(participation.user_id).to eq(user.id)
          expect(participation.rdv_id).to eq(rdv.id)
          expect(participation.created_by).to eq("user")
          expect(participation.follow_up_id).to eq(follow_up.id)
        end

        context "when it is an old update" do
          let!(:additional_attributes) { { last_webhook_update_received_at: "2021-09-08 11:05:00 UTC" } }
          let!(:rdv) do
            create(
              :rdv,
              rdv_solidarites_rdv_id: rdv_solidarites_rdv_id,
              last_webhook_update_received_at: "2021-09-08 11:06:00 UTC"
            )
          end

          it "does not update the rdv" do
            subject
            expect(rdv.starts_at).not_to eq(starts_at)
            expect(rdv.duration_in_min).not_to eq(duration_in_min)
          end
        end
      end

      context "when the record does not exist" do
        let!(:rdv) { create(:rdv, rdv_solidarites_rdv_id: 95) }

        it "creates a new record with the attributes" do
          subject

          new_rdv = Rdv.order(:created_at).last
          expect(new_rdv.id).not_to eq(rdv.id)

          expect(new_rdv.starts_at).to eq(starts_at)
          expect(new_rdv.duration_in_min).to eq(duration_in_min)
          expect(new_rdv.status).to eq(status)
          expect(new_rdv.user_ids).to include(*user_ids)
          expect(new_rdv.id).not_to eq(rdv_solidarites_rdv_id)

          # it also creates a participation in this case
          participation = Participation.order(:created_at).last
          expect(participation.user_id).to eq(user.id)
          expect(participation.rdv_id).to eq(new_rdv.id)
          expect(participation.follow_up_id).to eq(follow_up.id)
        end
      end
    end
  end

  context "for an agent" do
    subject do
      described_class.call(klass: klass, rdv_solidarites_attributes: agent_attributes)
    end

    let!(:klass) { Agent }
    let!(:rdv_solidarites_agent_id) { 12 }
    let!(:agent_attributes) do
      { id: rdv_solidarites_agent_id, first_name: "Josiane", last_name: "balasko", email: "josiane.balasko@gmail.com",
        inclusion_connect_open_id_sub: "1234" }
    end

    describe "#call" do
      context "when the record exists" do
        let!(:agent) { create(:agent, rdv_solidarites_agent_id: rdv_solidarites_agent_id) }

        it "assigns the attributes" do
          subject
          agent.reload
          expect(agent).to have_attributes(
            agent_attributes.except(:id).merge(rdv_solidarites_agent_id: rdv_solidarites_agent_id)
          )
        end

        context "when it is an old update" do
          let!(:additional_attributes) { { last_webhook_update_received_at: "2021-09-08 11:05:00 UTC" } }
          let!(:agent) do
            create(
              :agent,
              first_name: "Frédéric",
              rdv_solidarites_agent_id: rdv_solidarites_agent_id,
              last_webhook_update_received_at: "2021-09-08 11:06:00 UTC"
            )
          end

          it "does not update the agent" do
            subject
            expect(agent.first_name).not_to eq("Josiane")
          end
        end
      end

      context "when the agent does not exist" do
        let!(:agent) { create(:agent, rdv_solidarites_agent_id: 95) }

        it "creates a new agent with the attributes" do
          subject

          new_agent = Agent.last
          expect(new_agent).to have_attributes(
            agent_attributes.except(:id).merge(rdv_solidarites_agent_id: rdv_solidarites_agent_id)
          )
        end
      end
    end
  end
end
