Rails.application.routes.draw do
  devise_for :users
  root to: "pages#landing"

  resources :events do
    member do
      get :check_in
    end

    resources :registrations, only: [:create] do
      member do
        patch :check_in
      end
    end

    resources :reviews, only: [:create, :update, :destroy]
  end

  resource :account, only: [:show]

  get "dashboard", to: "events#index"
  get "up" => "rails/health#show", as: :rails_health_check
  get '/dashboard', to: 'dashboard#index'
  get 'account/personal_info', to: 'accounts#personal_info', as: :personal_info
  patch 'account/update', to: 'accounts#update', as: :update_user
end
