module Previews
  class NotificationsController < Previews::BaseController
    before_action :set_user_example, :set_rdv_example, :set_notification_example,
                  only: [:index]

    attr_reader :user, :notification, :rdv

    include Notifications::SmsContent

    def index
      set_and_format_contents
    end

    private

    def set_user_example
      @user = User.new(
        first_name: "Camille", last_name: "Martin", title: "madame",
        address: "49 Rue Cavaignac, 13003 Marseille", phone_number: "+33607070707"
      )
    end

    def set_rdv_example
      @rdv = Rdv.new(
        motif: Motif.new(motif_category: @motif_category),
        organisation: @organisation,
        starts_at: Time.zone.parse("10/10/2022 09:00"),
        lieu: Lieu.new(name: "DINUM", address: "20 avenue de Ségur, 75007 Paris")
      )
    end

    def set_notification_example
      @notification = Notification.new(
        participation: Participation.new(
          rdv: @rdv,
          follow_up: FollowUp.new(motif_category: @motif_category),
          organisation: @organisation
        )
      )
    end

    def set_sms_contents
      @sms_contents = {}
      all_actions.each do |action|
        @sms_contents[action] = send("#{action}_content")
      end
    end

    def set_mail_contents
      @mail_contents = {}
      all_actions.each do |action|
        @mail_contents[action] = ApplicationController.render(
          template: "mailers/notification_mailer/#{action}",
          assigns: mailer_instance_variables,
          layout: nil
        )
      end
    end

    def all_actions
      [
        :presential_participation_created, :by_phone_participation_created,
        :presential_participation_updated, :by_phone_participation_updated,
        :presential_participation_reminder, :by_phone_participation_reminder,
        :participation_cancelled
      ]
    end

    def mailer_instance_variables
      {
        user: @user,
        notification: @notification,
        rdv: @notification.rdv,
        department: @notification.department,
        user_designation: @notification.user_designation,
        rdv_title: @notification.rdv_title,
        rdv_title_by_phone: @notification.rdv_title_by_phone,
        rdv_purpose: @notification.rdv_purpose,
        rdv_subject: @notification.rdv_subject,
        mandatory_warning: @notification.mandatory_warning,
        punishable_warning: @notification.punishable_warning,
        custom_sentence: @notification.custom_sentence,
        signature_lines: @notification.signature_lines,
        instruction_for_rdv: @notification.instruction_for_rdv
      }
    end

    def set_letter_contents
      @letter_contents = {}
      [:presential_participation_created, :by_phone_participation_created, :participation_cancelled].each do |action|
        @letter_contents[action] = ApplicationController.render(
          template: "letters/notifications/#{action}",
          layout: nil,
          locals: letter_locals
        )
      end
    end

    def letter_locals
      {
        department: @notification.department,
        user: @user,
        rdv: @notification.rdv,
        sender_name: @notification.letter_sender_name,
        direction_names: @notification.direction_names,
        signature_lines: @notification.signature_lines,
        motif_category: @notification.motif_category,
        organisation: @notification.organisation,
        display_europe_logos: @notification.display_europe_logos,
        display_department_logo: @notification.display_department_logo,
        display_france_travail_logo: @notification.display_france_travail_logo,
        sender_city: @notification.sender_city,
        rdv_title: @notification.rdv_title,
        rdv_title_by_phone: @notification.rdv_title_by_phone,
        user_designation: @notification.user_designation,
        mandatory_warning: @notification.mandatory_warning,
        punishable_warning: @notification.punishable_warning,
        instruction_for_rdv: @notification.instruction_for_rdv,
        rdv_purpose: @notification.rdv_purpose,
        rdv_subject: @notification.rdv_subject
      }
    end

    def overridable_texts
      # we sort the array because we want to highlight rdv_title_by_phone before rdv_title because it often contains it
      ::Configuration.template_override_attributes.sort_by(&:length).reverse.map do |attribute|
        @notification.send(attribute.gsub("template_", "").gsub("_override", ""))
      end.compact
    end
  end
end
