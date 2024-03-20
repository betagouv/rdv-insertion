class RetrieveFranceTravailAccessToken < BaseService
  API_SCOPES = ["api_rendezvous-partenairesv1"].freeze

  def call
    @redis = Redis.new

    if @redis.exists?("france_travail_access_token")
      set_access_token_in_result
      return
    end

    retrieve_france_travail_token
  ensure
    @redis.close
  end

  private

  def set_access_token_in_result
    result.access_token = @redis.get("france_travail_access_token")
  end

  def store_token_in_redis
    @redis.set("france_travail_access_token", @france_travail_access_token, ex: redis_key_duration)
  end

  def redis_key_duration
    # we expire the key 60 seconds before the token expires to be sure not to use an expired
    # access token when calling FT
    @expires_in - 60
  end

  def retrieve_france_travail_token
    ActiveRecord::Base.with_advisory_lock("france_travail_token") do
      # we check again in case a token has been retrieved while waiting for the lock to open
      return set_access_token_in_result if @redis.exists?("france_travail_token")

      request_token
      store_token_in_redis
      set_access_token_in_result
    end
  end

  def request_token
    response = connection.post do |req|
      req.body = URI.encode_www_form(request_body_params)
    end

    if response.success?
      response_body = JSON.parse(response.body)
      @france_travail_access_token, @expires_in = [
        response_body["access_token"], response_body["expires_in"]
      ]
    else
      fail!(
        "la requête d'authentification à FT n'a pas pu aboutir.\n" \
        "Status: #{response.status}\n Body: #{response.body}"
      )
    end
  end

  def connection
    @connection ||= Faraday.new(url: request_url) do |faraday|
      faraday.request :url_encoded
      faraday.options.timeout = 15.seconds
    end
  end

  def request_url
    uri = URI(ENV["FRANCE_TRAVAIL_AUTH_URL"])
    uri.query = request_url_params.to_query
    uri.to_s
  end

  def request_url_params
    { realm: "/partenaire" }
  end

  def request_body_params
    {
      grant_type: "client_credentials",
      client_id: ENV["FRANCE_TRAVAIL_API_KEY"],
      client_secret: ENV["FRANCE_TRAVAIL_API_SECRET"],
      scope: API_SCOPES.join(" ")
    }
  end
end
