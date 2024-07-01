module Invitations
  class GenerateLetter < BaseService
    require "rqrcode"

    include Messengers::GenerateLetter

    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      verify_format!(@invitation)
      verify_address!(@invitation)
      generate_letter
    end

    private

    def generate_letter
      @invitation.content = ApplicationController.render(
        template: "letters/invitations/#{@invitation.template_model}",
        layout: "pdf",
        locals: locals
      )
    end

    def locals # rubocop:disable Metrics/AbcSize
      {
        invitation: @invitation,
        department: @invitation.department,
        user: @invitation.user,
        organisation: organisation,
        sender_name: @invitation.letter_sender_name,
        direction_names: @invitation.direction_names,
        signature_lines: @invitation.signature_lines,
        help_address: @invitation.help_address,
        display_europe_logos: @invitation.display_europe_logos,
        display_department_logo: @invitation.display_department_logo,
        display_france_travail_logo: @invitation.display_france_travail_logo,
        sender_city: @invitation.sender_city,
        rdv_title: @invitation.rdv_title,
        user_designation: @invitation.user_designation,
        mandatory_warning: @invitation.mandatory_warning,
        punishable_warning: @invitation.punishable_warning,
        rdv_purpose: @invitation.rdv_purpose,
        rdv_subject: @invitation.rdv_subject,
        custom_sentence: @invitation.custom_sentence,
        invitation_url: @invitation.rdv_solidarites_public_url(with_protocol: false),
        qr_code: @invitation.qr_code,
        optional_rdv_subscription: @invitation.motif_category.optional_rdv_subscription?
      }
    end

    def organisation
      (@invitation.user.organisations & @invitation.organisations).last
    end
  end
end
