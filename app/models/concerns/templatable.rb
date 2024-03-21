module Templatable
  delegate :template, to: :motif_category
  delegate :mandatory_warning, :punishable_warning, :rdv_subject, :custom_sentence,
           to: :template

  def rdv_title
    current_category_configuration&.template_rdv_title_override || template.rdv_title
  end

  def rdv_title_by_phone
    current_category_configuration&.template_rdv_title_by_phone_override || template.rdv_title_by_phone
  end

  def user_designation
    current_category_configuration&.template_user_designation_override || template.user_designation
  end

  def rdv_purpose
    current_category_configuration&.template_rdv_purpose_override || template.rdv_purpose
  end
end
