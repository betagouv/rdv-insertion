module Invitations
  class SendSms < BaseService
    include Invitations::SmsContent
    include Messengers::SendSms

    attr_reader :invitation

    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      verify_format!(invitation)
      verify_phone_number!(invitation)
      send_sms(invitation.sms_sender_name, invitation.phone_number, content, invitation.record_identifier)
    end

    private

    def content
      if invitation.reminder?
        send("#{invitation.template_model}_reminder_content")
      else
        send("#{@invitation.template_model}_content")
      end
    end
  end
end
