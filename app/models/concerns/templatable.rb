module Templatable
  delegate :rdv_purpose, :rdv_title_by_phone, :rdv_title, :display_mandatory_warning,
           :display_punishable_warning,
           to: :message_template

  def message_template
    @message_template ||= Templating::ApplicantMessages.send(:"#{motif_category}")
  end
end
