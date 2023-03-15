class Configuration < ApplicationRecord
  belongs_to :motif_category
  belongs_to :file_configuration
  has_many :configurations_organisations, dependent: :delete_all
  has_many :organisations, through: :configurations_organisations

  validate :delays_validity, :invitation_formats_validity

  delegate :position, :name, to: :motif_category, prefix: true
  delegate :sheet_name, to: :file_configuration

  private

  def delays_validity
    return if number_of_days_to_accept_invitation <= number_of_days_before_action_required

    errors.add(:base, "Le délai de prise de rendez-vous communiqué au bénéficiaire ne peut pas être inférieur " \
                      "au délai d'expiration de l'invtation")
  end

  def invitation_formats_validity
    invitation_formats.each do |invitation_format|
      next if %w[sms email postal].include?(invitation_format)

      errors.add(:base, "Les formats d'invitation ne peuvent être que : sms, email, postal")
    end
  end
end
