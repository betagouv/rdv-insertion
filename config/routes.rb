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
    resources :agents, only: [:index, :show] do
      resource :impersonation, only: [:create, :destroy]
    end
    resources :departments, only: [:index, :show, :new, :create, :edit, :update]
    resources :organisations, only: [:index, :show, :new, :create, :edit, :update]
    resources :users, only: [:index, :show, :edit, :update]
    resources :motif_categories, only: [:index, :show, :new, :create, :edit, :update]
    resources :templates, only: [:index, :show]
    resources :orientation_types, only: [:index, :show, :new, :create, :edit, :update, :destroy]

    root to: "agents#index"
  end
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'

  scope module: 'website' do
    root "static_pages#welcome"
    get "mentions-legales", to: "static_pages#legal_notice"
    get "cgu", to: "static_pages#cgu"
    get "politique-de-confidentialite", to: "static_pages#privacy_policy"
    get "accessibilite", to: "static_pages#accessibility"

    resources :teleprocedure_landings, param: "department_number",
                                       path: '/parcours_insertion',
                                       only: [:show]
  end

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
        resource :parcours, only: [:show]
      end
      resources :invitations, only: [:create]
    end
    resources :follow_ups, module: :follow_ups, only: [] do
      resource :closings, only: [:create, :destroy]
    end
    # we need to nest in organisations the different category_configurations record to correctly authorize them
    resources :category_configurations, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    patch "category_configurations_positions/update", to: "category_configurations_positions#update"
    resources :tags, only: [:create, :destroy]
    resources :agent_roles, module: :agent_roles, only: [] do
      collection do
        resources :csv_export_authorizations, only: [:index]
        patch "csv_export_authorizations/batch_update", to: "csv_export_authorizations#batch_update"
      end
    end
    resources :invitation_dates_filterings, :creation_dates_filterings, only: [:new]
    resources :file_configurations, only: [:show, :new, :create, :edit, :update] do
      get :confirm_update
    end
    resources :messages_configurations, only: [:show, :new, :edit, :create, :update]
    resource :stats, only: [:show], controller: 'website/stats'
  end

  resources :stats, only: [:index], controller: 'website/stats' do
    get :deployment_map, on: :collection
  end

  resources :users, module: :users, only: [] do
    resources :rdvs, only: [:new]
    resources :parcours_documents, only: [:show, :update, :create, :destroy]
    resources :tag_assignations, only: [:index, :create, :destroy], param: :tag_id
    resources :referent_assignations, only: [:index, :create, :destroy], param: :agent_id
    resources :orientations, only: [:new, :create, :edit, :update, :destroy]
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
  resources :users_organisations, only: [:index, :create]
  resource :users_organisations, only: [:destroy]

  namespace :users do
    resources :searches, only: :create
  end

  resources :archives, only: [:new, :create, :update, :destroy]

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
        resource :parcours, only: [:show]
      end
      resources :invitations, only: [:create]
    end
    resources :follow_ups, module: :follow_ups, only: [] do
      resource :closings, only: [:create, :destroy]
    end
    resource :stats, only: [:show], controller: 'website/stats'
    resources :users_organisations, only: [:index, :create]
    resource :users_organisations, only: [:destroy]
    resources :invitation_dates_filterings, :creation_dates_filterings, only: [:new]
  end

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

  get "inclusion_connect/auth", to: "inclusion_connect#auth"
  get "inclusion_connect/callback", to: "inclusion_connect#callback"
  get "inclusion_connect/sign_out", to: "inclusion_connect#sign_out"

  post "/inbound_emails/brevo", to: "inbound_emails#brevo"
  namespace :brevo do
    post "mail_webhooks", to: "mail_webhooks#create"
    post "sms_webhooks/:record_identifier", to: "sms_webhooks#create", as: :sms_webhooks
  end

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
