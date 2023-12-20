describe Counters::InvitationsSent do
  before do
    Redis.new.flushall
  end

  describe "counter" do
    context "when invitation is sent" do
      it "changes counter" do
        Sidekiq::Testing.inline! do
          invitation = create(:invitation, sent_at: nil)
          invitation.update!(sent_at: Time.zone.now)
          expect(described_class.value(scope: invitation.department)).to eq(1)
          expect(described_class.value).to eq(1)
        end
      end
    end
  end
end