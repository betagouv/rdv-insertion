module FollowUps
  class Save < BaseService
    def initialize(follow_up:)
      @follow_up = follow_up
    end

    def call
      check_if_user_has_an_organisation_for_this_motif_category!
      save_record!(@follow_up)
      result.follow_up = @follow_up
    end

    private

    def check_if_user_has_an_organisation_for_this_motif_category!
      return if user.organisations_motif_category_ids.include?(@follow_up.motif_category_id)

      fail!("L'usager n'appartient à aucune organisation gérant cette catégorie de motifs")
    end

    def user = @follow_up.user
  end
end
