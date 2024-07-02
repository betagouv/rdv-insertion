module User::Address
  extend ActiveSupport::Concern

  included do
    squishes :address
    delegate :parsed_street_address, :parsed_post_code, :parsed_city, :parsed_post_code_and_city, to: :address_parser
  end

  private

  def address_parser
    Address::Parser.new(address)
  end
end
