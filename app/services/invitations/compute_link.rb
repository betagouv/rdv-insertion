module Invitations
  class ComputeLink < BaseService
    def initialize(rdv_solidarites_session:, invitation:)
      @invitation = invitation
      @rdv_solidarites_session = rdv_solidarites_session
    end

    def call
      retrieve_geolocalisation
      result.invitation_link = redirect_link
    end

    private

    def applicant
      @invitation.applicant
    end

    def retrieve_geolocalisation
      @retrieve_geolocalisation ||= RetrieveGeolocalisation.call(
        address: applicant.address, department_number: applicant.department.number
      )
    end

    def geo_attributes
      return {} unless retrieve_geolocalisation.success?

      {
        longitude: retrieve_geolocalisation.longitude,
        latitude: retrieve_geolocalisation.latitude,
        city_code: retrieve_geolocalisation.city_code,
        street_ban_id: retrieve_geolocalisation.street_ban_id
      }
    end

    def redirect_link
      "#{ENV['RDV_SOLIDARITES_URL']}/prendre_rdv?#{link_params.to_query}"
    end

    def link_params
      {
        departement: @invitation.department.number,
        address: address,
        invitation_token: @invitation.token,
        organisation_ids: @invitation.organisations.map(&:rdv_solidarites_organisation_id),
        motif_search_terms: @invitation.context
      }
        .merge(geo_attributes)
    end

    def address
      applicant.address.presence || @invitation.department.name_with_region
    end
  end
end
