class ConvocationsController < ApplicationController
  before_action :set_user, :set_organisations, :set_motif_category

  def new
    @convocation_links_by_type = {
      individuel: individuel_convocation_motif_link,
      collectif: collectif_convocation_link
    }
    @all_links = @convocation_links_by_type.values.compact
  end

  private

  def set_organisations
    @organisations =  policy_scope(Organisation)
                      .where(id: @user.unarchived_organisations)
                      .where(
                        department_level? ? { department_id: current_department_id } : { id: current_organisation_id }
                      )
  end

  def set_motif_category
    @motif_category = MotifCategory.find(params[:motif_category_id])
  end

  def set_user
    @user = policy_scope(User).find(params[:user_id])
  end

  def individuel_convocation_motif
    # first motif mentionning "convocation" in that category
    @individuel_convocation_motif ||=
      Motif.active.individuel.where(
        organisation_id: @organisations.map(&:id), motif_category: @motif_category
      ).find(&:convocation?)
  end

  def individuel_convocation_motif_link
    individuel_convocation_motif&.link_to_take_rdv_for(@user.rdv_solidarites_user_id)
  end

  def collectif_available_rdv
    # any collective rdv on that category
    @collectif_available_rdv ||=
      Rdv.collectif_and_available_for_reservation
         .where(motifs: { motif_category: @motif_category })
         .where(organisation: @organisations)
         .min_by(&:starts_at)
  end

  def collectif_convocation_link
    collectif_available_rdv&.add_user_url(@user.rdv_solidarites_user_id)
  end
end
