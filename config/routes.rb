Rails.application.routes.draw do
  devise_for :users

  # Logged-in users go straight to your existing dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Guests see a cute welcome page
  root "home#index"

  # Nice URLs (optional but clean)
  get "/dashboard", to: "dashboard#index"
end
