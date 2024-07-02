class CategoryConfiguration < ApplicationRecord
  include PhoneNumberValidation

  belongs_to :motif_category
  belongs_to :file_configuration
  belongs_to :organisation

  validates :organisation, uniqueness: { scope: :motif_category,
                                         message: "a déjà une category_configuration pour cette catégorie de motif" }
  validate :delays_validity, :invitation_formats_validity

  validates :notify_out_of_slots_email,
            presence: true,
            format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\z/ },
            if: -> { notify_out_of_slots? }

  validates :notify_rdv_changes_email,
            presence: true,
            format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}\z/ },
            if: -> { notify_rdv_changes? }

  validates :number_of_days_between_periodic_invites, numericality: { only_integer: true, greater_than: 13 },
                                                      allow_nil: true

  delegate :name, :short_name, to: :motif_category, prefix: true
  delegate :sheet_name, to: :file_configuration
  delegate :department, :rdv_solidarites_organisation_id, to: :organisation
  delegate :template, to: :motif_category

  def self.template_override_attributes
    attribute_names.select do |attribute_name|
      attribute_name.start_with?("template") && attribute_name.end_with?("override")
    end
  end

  def periodic_invites_activated?
    day_of_the_month_periodic_invites.present? || number_of_days_between_periodic_invites.present?
  end

  def phone_number
    attributes["phone_number"].presence || organisation.phone_number
  end

  private

  def delays_validity
    return if number_of_days_before_action_required > Invitation::NUMBER_OF_DAYS_BEFORE_REMINDER

    errors.add(:base, "Le délai d'expiration de l'invtation doit être supérieur " \
                      "à #{Invitation::NUMBER_OF_DAYS_BEFORE_REMINDER} jours")
  end

  def invitation_formats_validity
    invitation_formats.each do |invitation_format|
      next if %w[sms email postal].include?(invitation_format)

      errors.add(:base, "Les formats d'invitation ne peuvent être que : sms, email, postal")
    end
  end
end
