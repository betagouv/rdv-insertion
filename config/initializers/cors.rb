Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(/^(.*)rdv-insertion\.fr$/)
    resource "*", headers: :any, methods: [:get, :post, :patch, :put]
  end
end
