module RdvSolidarites
  class User < Base
    RECORD_ATTRIBUTES = [
      :id, :first_name, :last_name, :birth_date, :email, :phone_number,
      :birth_name, :address, :affiliation_number
    ].freeze
    attr_reader(*RECORD_ATTRIBUTES)

    def augmented_attributes
      payload = rdvi_user.nil? ? ::User.new.as_json.merge(@attributes) : rdvi_user.as_json.merge(@attributes)
      payload.except(:updated_at, :created_through, :follow_ups, :organisations, :archives)
    end

    def rdvi_user
      @rdvi_user ||= ::User.find_by(rdv_solidarites_user_id: @id)
    end
  end
end
