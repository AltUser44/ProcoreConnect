Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :integrations, only: %i[index show create update destroy] do
        resources :sync_logs, only: %i[index show]
        resources :webhook_events, only: %i[index show]
      end

      post "webhooks/:integration_id", to: "webhooks#receive", as: :webhook
    end
  end
end
