# app/controllers/debug_controller.rb
class DebugController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_development!
  before_action :setup_time_machine

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
    effective_date = TimeMachine.active? ? TimeMachine.simulated_date : Time.zone.today
    current_user.habits.update_all(completed_on: effective_date)

    # Update all streakling creatures (ensure they exist first)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }

    redirect_to root_path, notice: "Habits completed today — Creatures are happy!"
  end

  def reset
    current_user.habits.update_all(completed_on: Time.zone.today)
    current_user.habits.each { |habit| habit.ensure_streakling_creature!; habit.streakling_creature.update_streak_and_mood! }
    redirect_to root_path, notice: "Everything reset — Creatures are HAPPY again"
  end

  # Enhanced Time Machine Methods
  def reset_to_new
    # Reset habits to never completed
    current_user.habits.update_all(completed_on: nil)

    # Reset all creatures to initial state
    current_user.habits.each do |habit|
      creature = habit.streakling_creature
      if creature
        creature.update!(
          current_streak: 0,
          longest_streak: 0,
          mood: "happy",
          consecutive_missed_days: 0,
          is_dead: false,
          died_at: nil,
          revived_count: 0,
          stage: "egg",
          became_eternal_at: nil
        )
      else
        # Create new creature if none exists
        habit.create_streakling_creature!(
          streakling_name: "Little One",
          animal_type: "dragon",
          current_streak: 0,
          longest_streak: 0,
          mood: "happy",
          consecutive_missed_days: 0,
          is_dead: false,
          revived_count: 0,
          stage: "egg"
        )
      end
    end

    # Initialize time machine
    session[:time_machine] = {
      'active' => true,
      'simulated_date' => Date.today.to_s,
      'start_date' => Date.today.to_s,
      'completion_history' => {}
    }
    
    # Also set up TimeMachine session
    TimeMachine.session = session

    redirect_to root_path, notice: "🔄 Reset to brand new! Time machine activated. Today is #{Date.today.strftime('%B %d, %Y')}"
  end

  def next_day
    # Check if time machine exists, if not redirect
    unless session[:time_machine] && session[:time_machine]['active']
      redirect_to root_path, alert: "❌ Time machine not active! Reset to new first."
      return
    end

    # Get current date from session
    current_date = if session[:time_machine]['simulated_date']
      Date.parse(session[:time_machine]['simulated_date'])
    else
      session[:time_machine]['start_date'] ? Date.parse(session[:time_machine]['start_date']) : Time.zone.today
    end
    
    new_date = current_date.tomorrow
    
    # Update session - create new hash to ensure persistence
    tm_data = session[:time_machine].dup || {}
    tm_data['simulated_date'] = new_date.to_s
    session[:time_machine] = tm_data
    
    TimeMachine.session = session

    redirect_to root_path, notice: "⏭️ Advanced to next day: #{new_date.strftime('%B %d, %Y')}"
  end

  def previous_day
    # Check if time machine exists, if not redirect
    unless session[:time_machine] && session[:time_machine]['active']
      redirect_to root_path, alert: "❌ Time machine not active! Reset to new first."
      return
    end

    # Get current date from session
    current_date = if session[:time_machine]['simulated_date']
      Date.parse(session[:time_machine]['simulated_date'])
    else
      session[:time_machine]['start_date'] ? Date.parse(session[:time_machine]['start_date']) : Time.zone.today
    end
    
    start_date = if session[:time_machine]['start_date']
      Date.parse(session[:time_machine]['start_date'])
    else
      Time.zone.today
    end
    
    new_date = current_date.yesterday
    if new_date >= start_date
      # Update session - create new hash to ensure persistence
      tm_data = session[:time_machine].dup || {}
      tm_data['simulated_date'] = new_date.to_s
      session[:time_machine] = tm_data
      
      TimeMachine.session = session
      redirect_to root_path, notice: "⏮️ Went back to previous day: #{new_date.strftime('%B %d, %Y')}"
    else
      redirect_to root_path, alert: "❌ Cannot go before the starting date!"
    end
  end

  def exit_time_machine
    session.delete(:time_machine)
    TimeMachine.session = session
    redirect_to root_path, notice: "🕰️ Time machine deactivated. Back to real time!"
  end

  private

  def ensure_development!
    raise "Debug mode only works in development or test!" unless Rails.env.development? || Rails.env.test?
  end

  def setup_time_machine
    TimeMachine.session = session
  end

  def ensure_time_machine_active
    unless session[:time_machine] && session[:time_machine]['active']
      redirect_to root_path, alert: "❌ Time machine not active! Reset to new first."
    end
  end
end
