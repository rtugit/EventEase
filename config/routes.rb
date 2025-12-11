Rails.application.routes.draw do
  devise_for :users
  root to: "pages#landing"

  resources :events do
    member do
      get :check_in
    end

    resources :registrations, only: [:create]
    resources :reviews, only: [:create, :update, :destroy]
  end

  resources :registrations, only: [:destroy] do
    member do
      patch :check_in
    end
  end

  get "dashboard", to: "events#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
