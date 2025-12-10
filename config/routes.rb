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


  #route for new events
  get "events/new", to: "indexs#new"

  #route for creating events
  post "events", to: "indexs#create"

  #route for editing events
  get "events/:id/edit", to: "indexs#edit"

  #route for updatting events
  patch "events/:id", to: "indexs#update"

  #route for destroying events
  delete "events/:id", to: "indexs#destroy"

  #route for showing events
  get "/events/:id", to: "indexs#show"


end
