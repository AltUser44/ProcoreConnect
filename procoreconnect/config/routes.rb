Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post   "auth/register", to: "auth#register"
      post   "auth/login",    to: "auth#login"
      get    "auth/me",       to: "auth#me"
      delete "auth/logout",   to: "auth#logout"

      resources :integrations, only: %i[index show create update destroy] do
        resources :sync_logs, only: %i[index show]
        resources :webhook_events, only: %i[index show]
      end

      post "webhooks/:integration_id", to: "webhooks#receive", as: :webhook
    end
  end
end
