Rails.application.routes.draw do
  # ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
  # DEBUG TIME MACHINE — DEVELOPMENT AND TEST ENVIRONMENTS
  if Rails.env.development? || Rails.env.test?
    get 'debug/yesterday', as: :debug_yesterday
    get 'debug/kill', as: :debug_kill
    get 'debug/complete_today', as: :debug_complete_today
    get 'debug/reset', as: :debug_reset

    # Enhanced Time Machine
    get 'debug/reset_to_new', as: :debug_reset_to_new
    get 'debug/next_day', as: :debug_next_day
    get 'debug/previous_day', as: :debug_previous_day
    get 'debug/exit_time_machine', as: :debug_exit_time_machine
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
