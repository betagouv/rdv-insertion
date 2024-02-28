module Invitations
  class VerifyOrganisationCreneauxAvailability < BaseService
    def initialize(organisation_id:)
      @organisation = Organisation.find(organisation_id)
      # On prend le premier agent de l'organisation pour les appels à l'API RDVSP
      Current.agent = @organisation.agents.first
      @invitations_params_without_creneau = []
      @grouped_invitation_params_by_category = []
    end

    def call
      process_invitations
      process_invitations_params_without_creneau
      result.grouped_invitation_params_by_category = @grouped_invitation_params_by_category
    end

    private

    def process_invitations
      return if organisation_valid_invitations.empty?

      invitations_params.each do |params|
        @invitations_params_without_creneau << params unless creneau_available?(params)
      end
    end

    def invitations_params
      organisation_valid_invitations.select("DISTINCT ON (rdv_context_id) *").to_a.map do |invitation|
        invitation.link_params.symbolize_keys
      end
    end

    def organisation_valid_invitations
      @organisation.invitations.valid
    end

    def creneau_available?(params)
      RdvSolidaritesApi::RetrieveCreneauAvailability.call(link_params: params).creneau_availability
    end

    def process_invitations_params_without_creneau
      @invitations_params_without_creneau.each do |invitation_params|
        group_invitation_params_by_category(invitation_params)
      end
      @grouped_invitation_params_by_category
    end

    def group_invitation_params_by_category(invitation)
      motif_category_name = MotifCategory.find_by(short_name: invitation[:motif_category_short_name]).name
      city_code = invitation[:city_code]
      referent_ids = invitation[:referent_ids]
      category_params_group = find_or_initialize_category_params_group(motif_category_name)
      category_params_group[:invitations_counter] += 1
      category_params_group[:city_codes].add(city_code) if city_code.present?
      category_params_group[:referent_ids].merge(referent_ids) if referent_ids.present?
    end

    def find_or_initialize_category_params_group(motif_category_name)
      category_params_group = @grouped_invitation_params_by_category.find do |m|
        m[:motif_category_name] == motif_category_name
      end
      return category_params_group if category_params_group.present?

      category_params_group = { motif_category_name: motif_category_name, city_codes: Set.new, referent_ids: Set.new,
                                invitations_counter: 0 }
      @grouped_invitation_params_by_category << category_params_group
      category_params_group
    end
  end
end
