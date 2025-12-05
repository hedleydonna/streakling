class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :setup_time_machine

  def index
    # Welcome dashboard – we'll add streaklings here later
  end

  private

  def setup_time_machine
    TimeMachine.session = session
  end
end
