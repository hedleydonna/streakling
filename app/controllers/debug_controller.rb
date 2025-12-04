# app/controllers/debug_controller.rb
class DebugController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_development!

  def yesterday
    current_user.habits.update_all(completed_on: 1.day.ago.to_date)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }
    redirect_to root_path, notice: "All habits set to YESTERDAY — Creatures are sad"
  end

  def kill
    current_user.habits.update_all(completed_on: 2.days.ago.to_date)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }
    redirect_to root_path, alert: "CREATURES ARE DEAD"
  end

  def complete_today
    current_user.habits.update_all(completed_on: Time.zone.today)

    # Update all streakling creatures (ensure they exist first)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }

    redirect_to root_path, notice: "Habits completed today — Creatures are happy!"
  end

  def reset
    current_user.habits.update_all(completed_on: Time.zone.today)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }
    redirect_to root_path, notice: "Everything reset — Creatures are HAPPY again"
  end

  private

  def ensure_development!
    raise "Debug mode only works in development or test!" unless Rails.env.development? || Rails.env.test?
  end
end
