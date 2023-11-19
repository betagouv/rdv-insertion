module RdvSolidaritesApi
  class RetrieveCreneauAvailability < Base
    def initialize(link_params:, rdv_solidarites_session:)
      @link_params = link_params
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      request!
      result.creneau_availability = rdv_solidarites_response_body["creneau_availability"]
    end

    private

    def rdv_solidarites_response
      @rdv_solidarites_response ||= rdv_solidarites_client.get_creneau_availability(@link_params)
    end
  end
end
