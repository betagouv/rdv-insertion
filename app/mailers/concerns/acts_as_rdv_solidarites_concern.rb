module ActsAsRdvSolidaritesConcern
  extend ActiveSupport::Concern

  included do
    after_action :rewrite_external_urls

    default from: "rdv-solidarites <support@rdv-insertion.fr>"
    layout "rdv_solidarites"
  end

  def rewrite_external_urls
    # We change all non assets URLs in favor of Rdvs redirection URL
    @_message.body.raw_source.gsub!(/#{Regexp.escape(ENV['HOST'])}(?!\/assets)/, ENV["RDV_SOLIDARITES_URL"] + "/rdvi")
  end
end