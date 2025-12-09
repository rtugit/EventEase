Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :events, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :registrations, only: [:create]
  end

  resources :registrations, only: [:destroy] do
    member do
      patch :check_in
    end
  end

  get "dashboard", to: "events#index"

  get "up" => "rails/health#show", as: :rails_health_check
end
