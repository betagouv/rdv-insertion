require 'sidekiq/web'
require 'sidekiq/cron/web'

def check_auth(username, password, service)
  ActiveSupport::SecurityUtils.secure_compare(
    Digest::SHA256.hexdigest(username),
    Digest::SHA256.hexdigest(ENV["#{service}_USERNAME"])
  ) & ActiveSupport::SecurityUtils.secure_compare(
    Digest::SHA256.hexdigest(password),
    Digest::SHA256.hexdigest(ENV["#{service}_PASSWORD"])
  )
end

Rails.application.routes.draw do
  namespace :super_admins do
    resources :departments, only: [:index, :show, :new, :create, :edit, :update]
    resources :organisations, only: [:index, :show, :new, :create, :edit, :update]
    resources :users, only: [:index, :show, :edit, :update]
    resources :motif_categories, only: [:index, :show, :new, :create, :edit, :update]
    resources :templates, only: [:index, :show]

    root to: "organisations#index"
  end
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'

  root "static_pages#welcome"
  get "mentions-legales", to: "static_pages#legal_notice"
  get "cgu", to: "static_pages#cgu"
  get "politique-de-confidentialite", to: "static_pages#privacy_policy"
  get "accessibilite", to: "static_pages#accessibility"

  resources :teleprocedure_landings, param: "department_number",
                                     path: '/parcours_insertion',
                                     only: [:show]

  resources :organisations, only: [:index, :new, :show, :edit, :create, :update] do
    get :geolocated, on: :collection
    get :search, on: :collection
    resources :users, only: [:index, :create, :show, :update, :edit, :new] do
      collection do
        get :default_list
        scope module: :users do
          resources :uploads, only: [:new]
          get "uploads/category_selection", to: "uploads#category_selection"
          resources :batch_actions, only: [:new]
        end
      end
      scope module: :users do
        resources :follow_ups, only: [:index]
      end
      resources :invitations, only: [:create]
      resources :tag_assignations, only: [:index, :create] do
        delete :destroy, on: :collection
      end
    end
    # we need to nest in organisations the different category_configurations record to correctly authorize them
    resources :category_configurations, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    patch "category_configurations_positions/update", to: "category_configurations_positions#update"
    resources :tags, only: [:create, :destroy]
    resources :file_configurations, only: [:show, :new, :create, :edit, :update] do
      get :confirm_update
    end
    resources :messages_configurations, only: [:show, :new, :edit, :create, :update]
    resource :stats, only: [:show]
  end

  resources :stats, only: [:index] do
    get :deployment_map, on: :collection
  end

  resources :users, module: :users, only: [] do
    resource :parcours, only: [:show]
    resources :orientations, only: [:new, :create, :edit, :update, :destroy]
    resources :parcours_documents, only: [:show, :update, :create, :destroy]
    resources :rdvs, only: [:new]
  end

  get "invitation", to: "invitations#invitation_code", as: :invitation_landing
  get '/r/:uuid', to: "invitations#redirect_shortcut", as: :redirect_invitation_shortcut
  resources :invitations, only: [] do
    get :redirect, on: :collection
  end

  resources :csv_exports, only: :show

  resources :convocations, only: [:new]

  resources :participations, only: [:update]
  resources :follow_ups, only: [:create]

  resources :follow_ups, module: :follow_ups, only: [] do
    resource :closings, only: [:create, :destroy]
  end

  namespace :users do
    resources :searches, only: :create
  end

  resources :archives, only: [:create, :destroy]

  namespace :organisations do
    resources :user_added_notifications, only: [:create]
  end

  resources :participations, only: [] do
    resources :notifications, only: :create
  end

  namespace :previews do
    resources :invitations, only: [:index]
    resources :notifications, only: [:index]
  end

  namespace :carnet_de_bord do
    resources :carnets, only: [:create]
  end

  resources :users_organisations, only: [:index, :create]
  resource :users_organisations, only: [:destroy]
  resources :referent_assignations, only: [:index, :create]
  resource :referent_assignations, only: [:destroy]

  resources :departments, only: [] do
    patch "category_configurations_positions/update", to: "category_configurations_positions#update"
    resources :department_organisations, only: [:index], as: :organisations, path: "/organisations"
    resources :users, only: [:index, :new, :create, :show, :edit, :update] do
      collection do
        scope module: :users do
          resources :uploads, only: [:new]
          get "uploads/category_selection", to: "uploads#category_selection"
          resources :batch_actions, only: [:new]
        end
        get :default_list
      end
      scope module: :users do
        resources :follow_ups, only: [:index]
      end
      resources :invitations, only: [:create]
      resources :tag_assignations, only: [:index, :create] do
        delete :destroy, on: :collection
      end
    end
    resource :stats, only: [:show]
  end
  resources :invitation_dates_filterings, :creation_dates_filterings, only: [:new]

  namespace :api do
    namespace :v1 do
      resources :departments, param: "department_number", only: [:show]
      resources :rdvs, param: "uuid", only: [:show]
      resources :organisations, param: "rdv_solidarites_organisation_id", only: [] do
        member do
          resources :users, only: [] do
            post :create_and_invite_many, on: :collection
            post :create_and_invite, on: :collection
          end
          post "applicants/create_and_invite_many", to: "users#create_and_invite_many"
        end
      end
    end
  end

  # Error pages
  get "404", to: "errors#not_found"
  get "422", to: "errors#unprocessable_entity"
  get "500", to: "errors#internal_server_error"

  # redirect logos that used to be served through webpacker
  get "/packs/media/images/logos/*old_path", to: "asset_redirections#new", format: false

  resources :rdv_solidarites_webhooks, only: [:create]

  resources :sessions, only: [:create]
  get '/sign_in', to: "sessions#new"
  delete '/sign_out', to: "sessions#destroy"

  get "inclusion_connect/auth" => "inclusion_connect#auth"
  get "inclusion_connect/callback" => "inclusion_connect#callback"

  post "/inbound_emails/brevo", to: "inbound_emails#brevo"
  post "/brevo_mail_webhooks", to: "brevo_mail_webhooks#create"
  post "/brevo_sms_webhooks/:invitation_id", to: "brevo_sms_webhooks#create"

  if ENV["SIDEKIQ_USERNAME"] && ENV["SIDEKIQ_PASSWORD"]
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      check_auth(username, password, "SIDEKIQ")
    end
  end
  mount Sidekiq::Web, at: "/sidekiq"

  if Rails.env.development?
    # LetterOpener
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
