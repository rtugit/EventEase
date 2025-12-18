Rails.application.routes.draw do
  devise_for :users
  root to: "pages#landing"

  get 'events/search_suggestions', to: 'events#search_suggestions'

  resources :events do
    member do
      get :check_in
    end
    resources :registrations, only: [:create, :destroy] do
      member do
        patch :check_in
      end
    end
    resources :reviews, only: [:create, :update, :destroy]
    resources :comments, only: [:create, :update, :destroy]
  end

  namespace :api do
    resources :ai_images, only: [:create]
  end

  resource :account, only: [:show]

  get "dashboard", to: "events#index"
  get "up" => "rails/health#show", as: :rails_health_check
  get 'account/personal_info', to: 'accounts#personal_info', as: :personal_info
  patch 'account/update', to: 'accounts#update', as: :update_user
  post 'ai/chat', to: 'ai#chat'
  post 'ai/generate_content', to: 'ai#generate_content'
end
