Rails.application.routes.draw do
  if defined?(Rswag::Ui)
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

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
      resources :careers, only: %i[create]
      resource :cart, only: [ :show, :destroy ] do
        resources :items, controller: "cart_items", only: [ :create, :update, :destroy ]
      end
      resources :delivery_addresses
      resources :orders, only: %i[index show update] do
        resource :delivery, only: :show
      end
      resources :payments, only: :create do
        collection do
          get :payment_return
        end
      end
      post "payments/cashfree/webhook", to: "payments/cashfree_webhooks#create"
      get "specials", to: "specials#index"

      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"
      post "auth/forgot_password", to: "auth#forgot_password"
      post "auth/reset_password", to: "auth#reset_password"
      patch "profile", to: "auth#update_profile"

      namespace :admin do
        resources :menus
        resources :menu_categories
        resources :menu_items
        resources :customers
        resources :orders, only: %i[index show]
        resources :tables, only: %i[index show create update]
        resources :table_reservations, only: %i[index show destroy] do
          member do
            patch :deactivate
          end
        end
        resources :parties_reservations, only: %i[index show]
        resources :catering_reservations, only: %i[index show]
        resources :jobs
        resources :job_applications, only: %i[index show]
      end
    end
  end

  mount ActiveStorage::Engine => "/rails/active_storage"
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
