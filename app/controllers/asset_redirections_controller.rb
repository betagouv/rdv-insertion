# For old images served through webpacker in old emails to still be served
class AssetRedirectionsController < ApplicationController
  skip_before_action :authenticate_agent!

  include ActionView::Helpers::AssetUrlHelper

  def new
    old_logo_path, logo_format = params[:old_path].split(".")
    # we remove the fingerprint from the logo path
    logo_name = old_logo_path.match(/^(.+)-([a-f0-9]+)/)[1]

    return if logo_name.blank?

    blob = ActiveStorage::Blob.find_by(filename: "#{logo_name}.#{logo_format}")
    return unless blob

    redirect_to blob.url, status: :moved_permanently
  end
end
