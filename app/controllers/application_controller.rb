class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :set_sentry_context

  include AuthorizationConcern
  include AuthenticatedControllerConcern
  include BeforeActionOverride
  include EnvironmentsHelper

  private

  def set_sentry_context
    Sentry.set_user(sentry_user)
  end

  def sentry_user
    {
      id: current_agent&.id,
      email: current_agent&.email
    }.compact
  end

  def page
    params[:page] || 1
  end

  def department_level?
    params[:department_id].present?
  end

  def sync_user_with_rdv_solidarites(user)
    sync = UpsertRdvSolidaritesUser.call(
      user: user,
      organisation: user.organisations.first,
      rdv_solidarites_session: rdv_solidarites_session
    )
    return if sync.success?

    respond_to do |format|
      format.turbo_stream { flash.now[:error] = "L'utilisateur n'est plus lié à rdv-solidarités: #{sync.errors}" }
      format.json { render json: { errors: sync.errors }, status: :unprocessable_entity }
    end
  end
end
