Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Collections and nested resources
  resources :collections do
    member do
      get :statistics
    end
    resources :items, shallow: true do
      member do
        get :move
        patch :relocate
      end
    end
    resources :storage_units, shallow: true do
      member do
        get :items
      end
    end
    get "items/loose", to: "items#loose", as: :loose_items
  end

  # MTGJSON browsing (Phase 1: Card Discovery)
  resources :sets, only: [ :index, :show ], param: :code
  resources :cards, only: [ :index, :show ], param: :uuid

  # Root route
  root "collections#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
