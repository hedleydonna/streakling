require "test_helper"

class TimeMachineTest < ActiveSupport::TestCase
  setup do
    # Clear any existing session state
    TimeMachine.reset
    @session = {}
    TimeMachine.session = @session
  end

  test "should return false when inactive" do
    assert_not TimeMachine.active?
  end

  test "should return true when active" do
    @session[:time_machine] = { 'active' => true }
    assert TimeMachine.active?
  end

  test "should return real date when inactive" do
    assert_equal Time.zone.today, TimeMachine.simulated_date
  end

  test "should return simulated date when active" do
    test_date = Time.zone.today + 5.days
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => test_date.to_s
    }
    assert_equal test_date, TimeMachine.simulated_date
  end

  test "should set simulated date" do
    test_date = Time.zone.today + 3.days
    @session[:time_machine] = { 'active' => true }
    
    TimeMachine.simulated_date = test_date
    
    assert_equal test_date.to_s, @session[:time_machine]['simulated_date']
    assert_equal test_date, TimeMachine.simulated_date
  end

  test "should return start_date when set" do
    start_date = Time.zone.today - 1.day
    @session[:time_machine] = {
      'active' => true,
      'start_date' => start_date.to_s
    }
    assert_equal start_date, TimeMachine.start_date
  end

  test "should return today as fallback for start_date when not set" do
    @session[:time_machine] = { 'active' => true }
    assert_equal Time.zone.today, TimeMachine.start_date
  end

  test "should calculate days_since_start correctly" do
    start_date = Time.zone.today - 1.day
    simulated_date = Time.zone.today + 5.days
    @session[:time_machine] = {
      'active' => true,
      'start_date' => start_date.to_s,
      'simulated_date' => simulated_date.to_s
    }
    
    assert_equal 6, TimeMachine.days_since_start
  end

  test "should advance date by 1 day with next_day!" do
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s
    }
    
    original_date = TimeMachine.simulated_date
    TimeMachine.next_day!
    
    assert_equal original_date + 1.day, TimeMachine.simulated_date
  end

  test "should advance date by specified days with advance_days!" do
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s
    }
    
    original_date = TimeMachine.simulated_date
    
    # Advance by 7 days
    TimeMachine.advance_days!(7)
    assert_equal original_date + 7.days, TimeMachine.simulated_date
    
    # Advance by 1 day
    TimeMachine.advance_days!(1)
    assert_equal original_date + 8.days, TimeMachine.simulated_date
  end

  test "next_day! should call advance_days! with 1" do
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s
    }
    
    original_date = TimeMachine.simulated_date
    
    TimeMachine.next_day!
    
    assert_equal original_date + 1.day, TimeMachine.simulated_date
  end

  test "should record completion in history" do
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s,
      'completion_history' => {}
    }
    
    habit_id = 1
    date = Time.zone.today
    
    TimeMachine.record_completion(habit_id, date, true)
    
    history = TimeMachine.completion_history_for_date(date)
    assert_equal true, history[habit_id.to_s]
  end

  test "should retrieve completion history for date" do
    date = Time.zone.today
    @session[:time_machine] = {
      'active' => true,
      'completion_history' => {
        date.to_s => {
          '1' => true,
          '2' => false
        }
      }
    }
    
    history = TimeMachine.completion_history_for_date(date)
    assert_equal true, history['1']
    assert_equal false, history['2']
  end

  test "should return empty hash for missing completion history" do
    date = Time.zone.today
    @session[:time_machine] = {
      'active' => true,
      'completion_history' => {}
    }
    
    history = TimeMachine.completion_history_for_date(date)
    assert_equal({}, history)
  end

  test "should reset session data" do
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => Time.zone.today.to_s
    }
    
    TimeMachine.reset
    
    # Reset clears the hash content, making it empty
    assert_equal({}, @session[:time_machine] || {})
  end

  test "should handle month boundaries when advancing dates" do
    # Set date to last day of month
    last_day = Time.zone.today.end_of_month
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => last_day.to_s
    }
    
    TimeMachine.next_day!
    
    # Should be first day of next month
    assert_equal 1, TimeMachine.simulated_date.day
  end

  test "should handle year boundaries when advancing dates" do
    # Set date to last day of year
    last_day = Date.new(Time.zone.today.year, 12, 31)
    @session[:time_machine] = {
      'active' => true,
      'simulated_date' => last_day.to_s
    }
    
    TimeMachine.next_day!
    
    # Should be first day of next year
    assert_equal Time.zone.today.year + 1, TimeMachine.simulated_date.year
    assert_equal 1, TimeMachine.simulated_date.month
    assert_equal 1, TimeMachine.simulated_date.day
  end
end

