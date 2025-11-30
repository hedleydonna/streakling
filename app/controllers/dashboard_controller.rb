class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Welcome dashboard – we'll add streaklings here later
  end
end
