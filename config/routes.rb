Rails.application.routes.draw do
  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
  # TIME MACHINE — DEVELOPMENT AND TEST ENVIRONMENTS
  if Rails.env.development? || Rails.env.test?
    get 'debug/activate_time_machine', to: 'debug#activate', as: :debug_activate_time_machine
    get 'debug/deactivate_time_machine', to: 'debug#deactivate', as: :debug_deactivate_time_machine
    post 'debug/next_day', to: 'debug#next_day', as: :debug_next_day
    post 'debug/next_7_days', to: 'debug#next_7_days', as: :debug_next_7_days
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
