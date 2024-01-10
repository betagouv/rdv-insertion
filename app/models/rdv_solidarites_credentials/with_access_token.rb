module RdvSolidaritesCredentials
  class WithAccessToken < Base
    def initialize(uid:, client:, access_token:) # rubocop:disable Lint/MissingSuper
      @uid = uid
      @client = client
      @access_token = access_token
    end

    def valid?
      required_attributes_present? && token_valid?
    end

    def to_h
      {
        "uid" => @uid,
        "client" => @client,
        "access-token" => @access_token
      }
    end

    private

    def required_attributes_present?
      [@uid, @client, @access_token].all?(&:present?)
    end

    def token_valid?
      validate_token = rdv_solidarites_client.validate_token
      return false unless validate_token.success?

      response_body = JSON.parse(validate_token.body)
      response_body["data"]["uid"] == @uid
    end

    def rdv_solidarites_client
      @rdv_solidarites_client ||= RdvSolidaritesClient.new(rdv_solidarites_credentials: to_h)
    end
  end
end
