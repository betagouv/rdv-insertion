module Invitations
  class SendSms < BaseService
    include Rails.application.routes.url_helpers

    def initialize(invitation:, phone_number:)
      @invitation = invitation
      @phone_number = phone_number
    end

    def call
      check_phone_number!
      send_sms
    end

    private

    def check_phone_number!
      fail!("le téléphone doit être renseigné") if @phone_number.blank?
    end

    def send_sms
      Rails.logger.info(content)
      return if Rails.env.development?

      SendTransactionalSms.call(phone_number: @phone_number, content: content)
    end

    def content
      "Bonjour,\nVous êtes allocataire du RSA. Vous devez bénéficier d'un accompagnement obligatoire dans " \
        "le cadre de vos démarches d'insertion. Le département #{department.number} (#{department.name.capitalize}) " \
        "vous invite à prendre rendez-vous auprès d'un référent afin d'échanger sur votre situation.\n" \
        "Vous devez prendre rendez-vous en ligne à l'adresse suivante: " \
        "#{redirect_invitations_url(params: { token: @invitation.token }, host: ENV['HOST'])}\n" \
        "En cas d'absence, une sanction pourra être prononcée. Pour tout problème, contactez " \
        "le secrétariat au #{department.phone_number}."
    end

    def department
      @invitation.department
    end

    def applicant
      @invitation.applicant
    end
  end
end
