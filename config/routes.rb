Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :menus, only: %i[index show]
      resources :menu_categories, only: %i[index show]
      resources :menu_items, only: %i[index show]
      resources :events, only: %i[index show]
      get "specials", to: "specials#index"
    end
  end
end
