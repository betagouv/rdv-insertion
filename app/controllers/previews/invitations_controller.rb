module Previews
  class InvitationsController < Previews::BaseController
    require "rqrcode"

    before_action :set_user_example, :set_invitation_example, only: [:index]

    attr_reader :user, :invitation

    include Invitations::SmsContent

    def index
      set_and_format_contents
    end

    private

    def set_invitation_example
      @invitation = Invitation.new(
        user: @user, organisations: [@organisation],
        follow_up: FollowUp.new(motif_category: @motif_category),
        valid_until: @category_configuration.number_of_days_before_action_required.days.from_now,
        help_phone_number: @category_configuration.phone_number,
        department: @department,
        uuid: SecureRandom.send(:choose, [*"A".."Z", *"0".."9"], 8)
      )
      # needed to access @invitation.category_configurations when the record linking @invitation and @organisation
      # is not persisted
      @invitation.association(:category_configurations).instance_variable_set("@target", [@category_configuration])
    end

    def set_user_example
      @user = User.new(
        first_name: "Camille", last_name: "Martin", title: "madame",
        address: "49 Rue Cavaignac, 13003 Marseille"
      )
    end

    def set_sms_contents
      @sms_contents = { first_invitation: send("#{@template.model}_content") }
      return unless respond_to?("#{@template.model}_reminder_content", true)

      @sms_contents.merge!(invitation_reminder: send("#{@template.model}_reminder_content"))
    end

    def set_mail_contents
      @mail_contents = {
        first_invitation: ApplicationController.render(
          template: "mailers/invitation_mailer/#{@template.model}_invitation",
          assigns: mailer_instance_variables,
          layout: nil
        )
      }
      return unless InvitationMailer.respond_to?("#{@template.model}_invitation_reminder")

      @mail_contents.merge!(
        invitation_reminder: ApplicationController.render(
          template: "mailers/invitation_mailer/#{@template.model}_invitation_reminder",
          assigns: mailer_instance_variables,
          layout: nil
        )
      )
    end

    def set_letter_contents
      @letter_contents = {
        first_invitation: ApplicationController.render(
          template: "letters/invitations/#{@template.model}",
          layout: nil,
          locals: letter_locals
        )
      }
    end

    def mailer_instance_variables
      {
        user: @user,
        invitation: @invitation,
        department: @invitation.department,
        user_designation: @invitation.user_designation,
        rdv_title: @invitation.rdv_title,
        rdv_purpose: @invitation.rdv_purpose,
        rdv_subject: @invitation.rdv_subject,
        mandatory_warning: @invitation.mandatory_warning,
        punishable_warning: @invitation.punishable_warning,
        custom_sentence: @invitation.custom_sentence,
        signature_lines: @organisation.messages_configuration&.signature_lines,
        optional_rdv_subscription: @invitation.motif_category.optional_rdv_subscription?
      }
    end

    def letter_locals
      {
        invitation: @invitation,
        department: @department,
        user: @user,
        organisation: @organisation,
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

    def overridable_texts
      # we want to highlight rdv_title_by_phone before the rdv_title because the rdv_title_by_phone
      # is often the rdv_title with "téléphonique" added, so if we highlighted the rdv_title before,
      # only part of the rdv_title_by_phone would be highlighted. That's why we use sort_by(&:length)
      CategoryConfiguration.template_override_attributes.sort_by(&:length).reverse.map do |attribute|
        @invitation.send(attribute.gsub("template_", "").gsub("_override", ""))
      end.compact
    end
  end
end
