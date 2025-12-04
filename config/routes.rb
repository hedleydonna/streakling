Rails.application.routes.draw do
  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
  # DEBUG TIME MACHINE — ONLY IN DEVELOPMENT
  if Rails.env.development?
    get 'debug/yesterday'
    get 'debug/kill'
    get 'debug/complete_today'
    get 'debug/reset'
  end
  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←

  # Admin namespace - accessible to admin users
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    resources :users
    resources :habits
  end

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
end
