module Invitations
  class Validate < BaseService
    attr_reader :invitation

    delegate :applicant, :organisations, :motif_category, :valid_until, :motif_category_human, :department_id,
             to: :invitation

    def initialize(invitation:)
      @invitation = invitation
    end

    def call
      validate_organisations_are_not_from_different_departments
      validate_it_expires_in_more_than_5_days if @invitation.format_postal?
      validate_applicant_belongs_to_an_org_linked_to_motif_category
      validate_motif_of_this_category_is_defined_in_organisations
      validate_referents_are_assigned if @invitation.rdv_with_referents?
      validate_follow_up_motifs_are_defined if @invitation.rdv_with_referents?
    end

    private

    def validate_organisations_are_not_from_different_departments
      return if organisations.map(&:department_id).uniq == [department_id]

      result.errors << "Les organisations ne peuvent pas être liés à des départements différents de l'invitation"
    end

    def validate_it_expires_in_more_than_5_days
      return if valid_until > 5.days.from_now

      result.errors << "La durée de validité de l'invitation pour un courrier doit être supérieure à 5 jours"
    end

    def validate_applicant_belongs_to_an_org_linked_to_motif_category
      return if applicant.configurations_motif_categories.include?(motif_category)

      result.errors << "L'allocataire n'appartient pas à une organisation qui gère la catégorie #{motif_category_human}"
    end

    def validate_motif_of_this_category_is_defined_in_organisations
      return if organisations_motifs.map(&:category).include?(motif_category)

      result.errors << "Aucun motif de la catégorie #{motif_category_human} n'est défini sur RDV-Solidarités"
    end

    def validate_referents_are_assigned
      return if applicant.agent_ids.any?

      result.errors << "Un référent doit être assigné au bénéficiaire pour les rdvs avec référents"
    end

    def validate_follow_up_motifs_are_defined
      return if organisations_motifs.any? do |motif|
        motif.follow_up? && motif.category == motif_category
      end

      result.errors << "Aucun motif de suivi n'a été défini pour la catégorie #{motif_category_human}"
    end

    def organisations_motifs
      @organisations_motifs ||= Motif.where(organisation_id: organisations.map(&:id))
    end
  end
end
