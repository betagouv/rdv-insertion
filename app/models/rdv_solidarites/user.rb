module RdvSolidarites
  class User < Base
    RECORD_ATTRIBUTES = [
      :id, :first_name, :last_name, :birth_date, :email, :phone_number,
      :birth_name, :address, :affiliation_number, :organisation_ids
    ].freeze
    attr_reader(*RECORD_ATTRIBUTES)

    def deleted?
      email&.ends_with?("@deleted.rdv-solidarites.fr")
    end
  end
end
