Rails.application.routes.draw do
  get 'dashboard/index'
  # Devise routes for authentication
  devise_for :users

  # Root route redirects to login if not authenticated
  root to: redirect('/users/sign_in')

  # Authenticated users go to a dashboard (we'll create this next)
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  # Temporary dashboard route
  get 'dashboard', to: 'dashboard#index'
end
