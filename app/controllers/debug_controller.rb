# app/controllers/debug_controller.rb
class DebugController < ApplicationController
  before_action :ensure_development!

  def yesterday
    current_user.habits.update_all(completed_on: 1.day.ago.to_date)
    current_user.pet.update_mood_and_streak!
    redirect_to root_path, notice: "All habits set to YESTERDAY — Sparkles is sad"
  end

  def kill 
    current_user.habits.update_all(completed_on: 2.days.ago.to_date)
    current_user.pet.update_mood_and_streak!
    redirect_to root_path, alert: "SPARKLES IS DEAD"
  end

  def complete_today
    current_user.habits.update_all(completed_on: Time.zone.today)
  
    # FORCE RESURRECTION — ignore streak logic for testing
    if current_user.pet.dead?
      current_user.pet.update!(mood: :happy, level: current_user.pet.level + 20)
      flash[:resurrected] = true
      redirect_to root_path, notice: "SPARKLES HAS RISEN — CONFETTI INCOMING!"
      return
    end
  
    # Normal path if not dead
    current_user.pet.update_mood_and_streak!
    redirect_to root_path, notice: "Habits completed today"
  end

  def reset
      current_user.habits.update_all(completed_on: Time.zone.today)
    current_user.pet.update_mood_and_streak!
    redirect_to root_path, notice: "Everything reset — Sparkles is HAPPY again"
  end

  private

  def ensure_development!
    raise "Debug mode only works in development!" unless Rails.env.development?
  end
end
