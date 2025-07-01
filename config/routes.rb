Rails.application.routes.draw do
  resources :vehicles
  resources :paypal_accounts
  resources :bank_accounts
  resources :projects
  resources :expenses
  resources :notes
  root to: "reimboursements#index"
  resources :reimboursements do
    resources :notes, only: [ :create, :destroy ]
    member do
      get :approve_expenses
      patch :approve_expense
      patch :deny_expense
      patch :approve_reimboursement
    end
  end
  resources :roles
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  # Admin routes
  namespace :admin do
    resources :users, except: [ :new, :create ] do
      member do
        patch :deactivate
        patch :activate
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
