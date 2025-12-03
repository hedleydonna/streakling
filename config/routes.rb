Rails.application.routes.draw do
  get 'debug/yesterday'
  get 'debug/kill'
  get 'debug/complete_today'
  get 'debug/reset'
  resources :habits
  devise_for :users

  # Toggle route for authenticated users
  patch "habits/:id/toggle", to: "habits#toggle", as: :toggle_habit

  # Logged-in users go straight to your existing dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
    resources :habits, only: [:new, :create, :index]
  end

  # Guests see a cute welcome page
  root "home#index"

  # Nice URLs (optional but clean)
  get "/dashboard", to: "dashboard#index"


  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
  # DEBUG TIME MACHINE — ONLY IN DEVELOPMENT
  if Rails.env.development?
    namespace :debug do
      post :yesterday, action: :set_yesterday
      post :kill,      action: :kill
      post :complete,  action: :complete_today
      post :reset,     action: :reset
    end
  end
  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
end
