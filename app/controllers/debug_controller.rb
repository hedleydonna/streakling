# app/controllers/debug_controller.rb
class DebugController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_development!
  before_action :setup_time_machine

  def activate
    # Reset all habits and creatures to initial state (wrapped in transaction)
    ActiveRecord::Base.transaction do
      current_user.habits.includes(:streakling_creature).find_each do |habit|
        # Reset habit completion
        habit.update!(completed_on: nil)
        
        # Reset creature to initial state
        if habit.streakling_creature
          habit.streakling_creature.reset_to_new!
        end
      end
    end
    
    # Initialize time machine
    # Set start_date to yesterday so day count starts at 1 on activation
    session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s,
      'start_date' => (Time.zone.today - 1.day).to_s,
      'completion_history' => {}
    }
    
    # Set up TimeMachine session
    TimeMachine.session = session

    redirect_to root_path, notice: "🕰️ Time machine activated! All habits and creatures reset to initial state."
  end

  def deactivate
    # Clear time machine session
    session.delete(:time_machine)
    
    # Clear TimeMachine session
    TimeMachine.session = session

    redirect_to root_path, notice: "🕰️ Time machine deactivated. Back to real time!"
  end

  def next_day
    # Check if time machine is actually active BEFORE doing anything
    unless session[:time_machine] && session[:time_machine]['active']
      Rails.logger.warn "Time Machine: Session invalid on next_day attempt. Session: #{session[:time_machine].inspect}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Time machine is not active." }
        format.turbo_stream { head :bad_request }
      end
      return
    end
    
    # Ensure session is set up before advancing
    TimeMachine.session = session
    
    # Store original session state for debugging
    original_date = TimeMachine.simulated_date
    
    # Advance simulated date by 1 day
    TimeMachine.next_day!
    
    # CRITICAL: Rebuild session hash to ensure Rails detects the change
    # Preserve ALL existing data to prevent session corruption
    existing_data = session[:time_machine]
    session[:time_machine] = {
      'active' => existing_data['active'],
      'simulated_date' => TimeMachine.simulated_date.to_s,
      'start_date' => existing_data['start_date'],
      'completion_history' => existing_data.fetch('completion_history', {}).dup
    }
    
    # Re-setup TimeMachine session after session update
    TimeMachine.session = session
    
    # Verify session is still valid before proceeding
    unless session[:time_machine] && session[:time_machine]['active']
      Rails.logger.error "Time Machine: Session lost after update. Original date: #{original_date}, New date: #{TimeMachine.simulated_date}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Time machine session was lost. Please reactivate." }
        format.turbo_stream { head :bad_request }
      end
      return
    end
    
    # Load habits for turbo_stream template (ensure it's always an array)
    @habits = current_user.habits.includes(:streakling_creature).order(:created_at).to_a
    
    # Log successful advancement for debugging
    Rails.logger.info "Time Machine: Advanced from #{original_date} to #{TimeMachine.simulated_date}"

    respond_to do |format|
      format.html { redirect_to root_path, notice: "⏭️ Advanced to #{TimeMachine.simulated_date.strftime('%B %d, %Y')}" }
      format.turbo_stream
    end
  rescue => e
    Rails.logger.error "Time Machine Next Day Error: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Error advancing time: #{e.message}" }
      format.turbo_stream { head :bad_request }
    end
  end

  def next_7_days
    # Check if time machine is actually active BEFORE doing anything
    unless session[:time_machine] && session[:time_machine]['active']
      Rails.logger.warn "Time Machine: Session invalid on next_7_days attempt. Session: #{session[:time_machine].inspect}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Time machine is not active." }
        format.turbo_stream { head :bad_request }
      end
      return
    end
    
    # Ensure session is set up before advancing
    TimeMachine.session = session
    
    # Store original session state for debugging
    original_date = TimeMachine.simulated_date
    
    # For habits completed on the current day, add 6 to their streak (for the 6 skipped days)
    # Iterate through all habits and check if they were completed on the original date
    current_user.habits.includes(:streakling_creature).find_each do |habit|
      # Reload to ensure we have the latest data from DB
      habit.reload
      # Compare dates - both should be Date objects, but ensure type match
      habit_completed_date = habit.completed_on
      next unless habit_completed_date && habit_completed_date.to_date == original_date.to_date && habit.streakling_creature
      
      creature = habit.streakling_creature.reload
      creature.current_streak += 6
      creature.longest_streak = [creature.longest_streak, creature.current_streak].max
      creature.consecutive_missed_days = 0
      creature.mood = "happy"
      # Update stage based on new streak (use private method via send)
      creature.stage = creature.send(:effective_stage_key)
      creature.save!
      
      # Record completions for days 2-7 in completion history
      # Ensure TimeMachine session is set before recording
      TimeMachine.session = session
      (1..6).each do |day_offset|
        intermediate_date = original_date + day_offset.days
        TimeMachine.record_completion(habit.id, intermediate_date, true)
      end
    end
    
    # Advance simulated date by 7 days
    TimeMachine.advance_days!(7)
    
    # CRITICAL: Rebuild session hash to ensure Rails detects the change
    # Preserve ALL existing data to prevent session corruption
    existing_data = session[:time_machine]
    session[:time_machine] = {
      'active' => existing_data['active'],
      'simulated_date' => TimeMachine.simulated_date.to_s,
      'start_date' => existing_data['start_date'],
      'completion_history' => existing_data.fetch('completion_history', {}).dup
    }
    
    # Re-setup TimeMachine session after session update
    TimeMachine.session = session
    
    # Verify session is still valid before proceeding
    unless session[:time_machine] && session[:time_machine]['active']
      Rails.logger.error "Time Machine: Session lost after update. Original date: #{original_date}, New date: #{TimeMachine.simulated_date}"
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Time machine session was lost. Please reactivate." }
        format.turbo_stream { head :bad_request }
      end
      return
    end
    
    # Load habits for turbo_stream template (ensure it's always an array)
    @habits = current_user.habits.includes(:streakling_creature).order(:created_at).to_a
    
    # Log successful advancement for debugging
    Rails.logger.info "Time Machine: Advanced 7 days from #{original_date} to #{TimeMachine.simulated_date} (simulated completions for habits completed on #{original_date})"

    respond_to do |format|
      format.html { redirect_to root_path, notice: "⏩ Advanced 7 days to #{TimeMachine.simulated_date.strftime('%B %d, %Y')}" }
      format.turbo_stream { render 'next_day' }
    end
  rescue => e
    Rails.logger.error "Time Machine Next 7 Days Error: #{e.message}\n#{e.backtrace.join("\n")}"
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Error advancing time: #{e.message}" }
      format.turbo_stream { head :bad_request }
    end
  end

  private

  def ensure_development!
    raise "Debug mode only works in development or test!" unless Rails.env.development? || Rails.env.test?
  end

  def setup_time_machine
    TimeMachine.session = session
  end
end
