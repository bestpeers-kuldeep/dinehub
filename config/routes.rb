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
      resources :tables, only: %i[index]
      resources :reservations, only: %i[create]
      resources :parties_reservations, only: %i[create]
      resources :catering_reservations, only: %i[create]
      get "specials", to: "specials#index"
    end
  end

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
