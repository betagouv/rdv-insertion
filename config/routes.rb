require 'sidekiq/web'

def check_auth(username, password, service)
  ActiveSupport::SecurityUtils.secure_compare(
    ::Digest::SHA256.hexdigest(username),
    ::Digest::SHA256.hexdigest(ENV["#{service}_USERNAME"])
  ) & ActiveSupport::SecurityUtils.secure_compare(
    ::Digest::SHA256.hexdigest(password),
    ::Digest::SHA256.hexdigest(ENV["#{service}_PASSWORD"])
  )
end

Rails.application.routes.draw do
  root "static_pages#welcome"
  get "mentions-legales", to: "static_pages#legal_notice"
  get "politique-de-confidentialite", to: "static_pages#privacy_policy"
  get "accessibilite", to: "static_pages#accessibility"
  resources :organisations, only: [:index] do
    get :geolocated, on: :collection
    resources :applicants, only: [:index, :create, :show, :update, :edit, :new] do
      collection do
        resources :uploads, only: [:new]
        post :search
      end
      resources :invitations, only: [:create]
    end
  end

  resources :stats, only: [:index]

  resources :invitations, only: [] do
    get :redirect, on: :collection
  end

  resources :applicants, only: [] do
    post :search, on: :collection
  end

  resources :departments, only: [] do
    resources :applicants, only: [:index, :show, :edit, :update] do
      collection { resources :uploads, only: [:new] }
      resources :invitations, only: [:create]
    end
  end

  resources :rdv_solidarites_webhooks, only: [:create]

  resources :sessions, only: [:create]
  get '/sign_in', to: "sessions#new"
  delete '/sign_out', to: "sessions#destroy"

  if ENV["SIDEKIQ_USERNAME"] && ENV["SIDEKIQ_PASSWORD"]
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      check_auth(username, password, "SIDEKIQ")
    end
  end
  mount Sidekiq::Web, at: "/sidekiq"
end
