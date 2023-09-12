class ParticipationsController < ApplicationController
  before_action :set_participation, only: [:edit, :update]

  def edit; end

  def update
    @success = Participations::UpdateStatus.call(
      participation: @participation,
      rdv_solidarites_session: rdv_solidarites_session,
      participation_params: participation_params
    ).success?

    flash.now[:error] = "Impossible de changer le statut de ce rendez-vous." if @success
  end

  private

  def set_participation
    @participation = Participation.find(params[:id])
  end

  def participation_params
    params.require(:participation).permit(:status)
  end
end
