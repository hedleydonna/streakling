class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @users_count = User.count
    @habits_count = Habit.count
    @creatures_count = StreaklingCreature.count
    @dead_creatures_count = StreaklingCreature.where(is_dead: true).count
    @eternal_creatures_count = StreaklingCreature.where(stage: 'eternal').count
    @stages_count = Stage.count
  end

  private

  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "Access denied. Admin privileges required."
    end
  end
end
