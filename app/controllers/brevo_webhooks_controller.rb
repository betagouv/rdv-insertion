class BrevoWebhooksController < ApplicationController
  skip_before_action :authenticate_agent!, :verify_authenticity_token

  def create
    byebug
  end
end
