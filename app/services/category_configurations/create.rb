module CategoryConfigurations
  class Create < BaseService
    def initialize(category_configuration:)
      @category_configuration = category_configuration
    end

    def call
      CategoryConfiguration.transaction do
        activate_motif_category_on_rdvs_territory
        save_record!(@category_configuration)
      end
    end

    private

    def activate_motif_category_on_rdvs_territory
      @activate_motif_category_on_rdvs_territory ||= call_service!(
        RdvSolidaritesApi::CreateMotifCategoryTerritory,
        motif_category_short_name: @category_configuration.motif_category_short_name,
        organisation_id: @category_configuration.rdv_solidarites_organisation_id
      )
    end
  end
end
