class TestService < Notifications::NotifyApplicant
  def content
    "test"
  end
end

describe Notifications::NotifyApplicant, type: :service do
  subject do
    TestService.call(
      applicant: applicant, rdv_solidarites_rdv: rdv_solidarites_rdv, organisation: organisation
    )
  end

  let!(:phone_number) { "0782605941" }
  let!(:phone_number_formatted) { "+33782605941" }
  let!(:rdv_solidarites_rdv) do
    OpenStruct.new(id: rdv_solidarites_rdv_id)
  end
  let!(:department) { create(:department) }
  let!(:organisation) { create(:organisation, department: department) }
  let!(:rdv_solidarites_rdv_id) { 23 }
  let!(:applicant) { create(:applicant, phone_number: phone_number, organisations: [organisation]) }
  let!(:notification) { create(:notification, applicant: applicant, sent_at: nil) }
  let!(:event) { "rdv_created" }

  describe "#call" do
    before do
      allow_any_instance_of(TestService).to receive(:event).and_return(event)
      allow(Notification).to receive(:new).and_return(notification)
      allow(notification).to receive(:save).and_return(true)
      allow(SendTransactionalSms).to receive(:call).and_return(OpenStruct.new(success?: true))
      allow(notification).to receive(:save).and_return(true)
    end

    context "when the phone number is missing" do
      let!(:applicant) { create(:applicant, organisations: [organisation], phone_number: "") }

      it("is a success") { is_a_success }

      it "does not create a notification" do
        expect(Notification).not_to receive(:new)
        subject
      end

      it "does not send a sms" do
        expect(SendTransactionalSms).not_to receive(:call)
        subject
      end
    end

    it "creates a notification" do
      expect(Notification).to receive(:new)
        .with(event: event, applicant: applicant, rdv_solidarites_rdv_id: rdv_solidarites_rdv_id)
      expect(notification).to receive(:save)
      subject
    end

    it "sends the sms" do
      expect(SendTransactionalSms).to receive(:call)
        .with(phone_number_formatted: phone_number_formatted, sender_name: "Dept#{department.number}", content: "test")
      subject
    end

    it "updates the notification" do
      expect(notification).to receive(:save)
      subject
    end

    it "marks the notif as sent" do
      subject
      expect(notification.sent_at).not_to be_nil
    end

    context "when the applicants does not belong to the organisation" do
      let!(:another_organisation) { create(:organisation) }
      let!(:applicant) { create(:applicant, organisations: [another_organisation]) }

      it("is a failure") { is_a_failure }

      it "stores the error message" do
        expect(subject.errors).to eq(["l'allocataire ne peut ??tre invit?? car il n'appartient pas ?? l'organisation."])
      end
    end

    context "when the notification cannot be saved" do
      before do
        allow(notification).to receive(:save).and_return(false)
        allow(notification).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("some error")
      end

      it "does not send the sms" do
        expect(SendTransactionalSms).not_to receive(:call)
      end

      it("is a failure") { is_a_failure }

      it "stores the error message" do
        expect(subject.errors).to eq(["some error"])
      end
    end

    context "when the sms service fails" do
      before do
        allow(SendTransactionalSms).to receive(:call)
          .and_return(OpenStruct.new(success?: false, errors: ["bad request"]))
      end

      it("is a failure") { is_a_failure }

      it "stores the error message" do
        expect(subject.errors).to eq(["bad request"])
      end

      it "marks the notification as sent" do
        subject
        expect(notification.sent_at).to be_nil
      end
    end

    context "when the notification cannot be updated" do
      before do
        allow(notification).to receive(:save)
          .and_return(false)
        allow(notification).to receive_message_chain(:errors, :full_messages, :to_sentence)
          .and_return("some error")
      end

      it("is a failure") { is_a_failure }

      it "stores the error message" do
        expect(subject.errors).to eq(["some error"])
      end
    end
  end
end
