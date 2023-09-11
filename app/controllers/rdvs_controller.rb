class RdvsController < ApplicationController
  before_action :set_rdv, only: [:edit, :update]

  def edit; end

  def update
    RdvSolidaritesApi::UpdateRdv.call(
      rdv_solidarites_session: rdv_solidarites_session,
      rdv_solidarites_rdv_id: @rdv.rdv_solidarites_rdv_id,
      rdv_attributes: rdv_params
    )
  end

  private

  def set_rdv
    @rdv = Rdv.find(params[:id])
  end

  def rdv_params
    params.require(:rdv).permit(:status)
  end
end
