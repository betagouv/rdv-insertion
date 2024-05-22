class ApplicationController < ActionController::Base
  include AuthenticatedControllerConcern
  include AuthorizationConcern
  include CurrentStructure
  include NavigationHelper
  include PolicyHelper
  include BeforeActionOverride
  include EnvironmentsHelper
  include TurboStreamConcern

  protect_from_forgery with: :exception
  before_action :set_sentry_context

  # Needed to generate ActiveStorage urls locally, it sets the host and protocol
  include ActiveStorage::SetCurrent unless Rails.env.production?

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

  def sync_user_with_rdv_solidarites(user)
    sync = Users::SyncWithRdvSolidarites.call(user: user)
    return if sync.success?

    respond_to do |format|
      format.turbo_stream { flash.now[:error] = "L'utilisateur n'est plus lié à rdv-solidarités: #{sync.errors}" }
      format.json { render json: { errors: sync.errors }, status: :unprocessable_entity }
    end
  end
end
