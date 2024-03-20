describe SendConvocationRemindersJob do
  subject do
    described_class.new.perform
  end

  describe "#perform" do
    let!(:participation1) { create(:participation, id: 239, convocable: true) }
    let!(:participation2) { create(:participation, convocable: false) }
    let!(:participation3) { create(:participation, convocable: true) }
    let!(:participation4) { create(:participation, convocable: true, status: "revoked") }

    let!(:rdv1) { create(:rdv, starts_at: 2.days.from_now, participations: [participation1]) }
    let!(:rdv2) { create(:rdv, starts_at: 2.days.from_now, participations: [participation2]) }
    let!(:rdv3) { create(:rdv, starts_at: 3.days.from_now, participations: [participation3]) }
    let!(:rdv4) { create(:rdv, starts_at: 2.days.from_now, participations: [participation4]) }

    before do
      allow(NotifyParticipationsToUsersJob).to receive(:perform_async)
      allow(MattermostClient).to receive(:send_to_notif_channel)
    end

    it "notifies the convocable participation that starts in 2 days" do
      expect(NotifyParticipationsToUsersJob).to receive(:perform_async)
        .with([239], "reminder")
      subject
    end

    it "sends a notification to mattermost" do
      expect(MattermostClient).to receive(:send_to_notif_channel)
        .with(
          "📅 1 rappels de convocation en cours d'envoi!\n" \
          "Les participations sont: [239]"
        )
      subject
    end
  end
end
