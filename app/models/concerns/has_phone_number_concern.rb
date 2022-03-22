# Concern to include in application models
# Models need to have a :phone_number and a :phone_number_formatted attributes
module HasPhoneNumberConcern
  extend ActiveSupport::Concern

  included do
    validate :validate_phone_number
  end

  # See issue #1471 in RDV-Solidarités. This setup allows:
  # * international (e164) phone numbers
  # * “french format” (ten digits with a leading 0)
  # However, we need to special-case some ten-digit numbers,
  # because the ARCEP assigns some blocks of "O6 XX XX XX XX" numbers to DROM operators.
  # Guadeloupe | GP | +590 | 0690XXXXXX, 0691XXXXXX
  # Guyane     | GF | +594 | 0694XXXXXX
  # Martinique | MQ | +596 | 0696XXXXXX, 0697XXXXXX
  # Réunion    | RE | +262 | 0692XXXXXX, 0693XXXXXX
  # Mayotte    | YT | +262 | 0692XXXXXX, 0693XXXXXX
  # Cf: Plan national de numérotation téléphonique,
  # https://www.arcep.fr/uploads/tx_gsavis/05-1085.pdf  “Numéros mobiles à 10 chiffres”, page 6
  COUNTRY_CODES = [:FR, :GP, :GF, :MQ, :RE, :YT].freeze

  def phone_number_formatted
    parsed_number(phone_number)&.e164
  end

  def validate_phone_number
    return if phone_number.blank?

    errors.add(:phone_number, :invalid) unless phone_number_is_valid?
  end

  def phone_number_is_valid?
    parsed_number(phone_number).present?
  end

  def phone_number_is_mobile?
    types = parsed_number(phone_number)&.types
    types&.include?(:mobile)
  end

  def parsed_number(phone_number)
    return if phone_number.blank?

    COUNTRY_CODES.each do |country_code|
      parsed_attempt = Phonelib.parse(phone_number, country_code)
      return parsed_attempt if parsed_attempt.valid?
    end

    nil
  end
end
