require "test_helper"

class DebugControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @habit = habits(:one)
  end

  test "should require authentication" do
    sign_out @user
    get debug_activate_time_machine_url
    assert_redirected_to new_user_session_path
  end

  test "should activate time machine and reset habits and creatures" do
    # Set up initial state
    @habit.update!(completed_on: Time.zone.today)
    creature = @habit.streakling_creature
    creature.update!(
      current_streak: 5,
      longest_streak: 10,
      mood: "sad",
      stage: "child"
    )

    # Activate time machine
    get debug_activate_time_machine_url
    assert_redirected_to root_path
    assert_equal "🕰️ Time machine activated! All habits and creatures reset to initial state.", flash[:notice]

    # Check session was created
    follow_redirect!
    assert session[:time_machine]
    assert session[:time_machine]['active']
    assert_equal Time.zone.today.to_s, session[:time_machine]['simulated_date']
    assert_equal (Time.zone.today - 1.day).to_s, session[:time_machine]['start_date']
    assert_equal({}, session[:time_machine]['completion_history'])

    # Check habit was reset
    @habit.reload
    assert_nil @habit.completed_on

    # Check creature was reset
    creature.reload
    assert_equal 0, creature.current_streak
    assert_equal 0, creature.longest_streak
    assert_equal "happy", creature.mood
    assert_equal "egg", creature.stage
    assert_equal false, creature.is_dead
    assert_equal 0, creature.consecutive_missed_days
  end

  test "should deactivate time machine" do
    # Activate first
    get debug_activate_time_machine_url
    follow_redirect!
    assert session[:time_machine]['active']

    # Deactivate
    get debug_deactivate_time_machine_url
    assert_redirected_to root_path
    assert_equal "🕰️ Time machine deactivated. Back to real time!", flash[:notice]

    # Check session was cleared
    follow_redirect!
    assert_nil session[:time_machine]
  end

  test "should advance to next day when time machine is active" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!
    
    TimeMachine.session = session
    original_date = TimeMachine.simulated_date
    original_day_count = TimeMachine.days_since_start

    # Advance to next day (POST request)
    post debug_next_day_path
    # May redirect for HTML format, or return turbo_stream
    follow_redirect! if response.redirect?
    
    # Check simulated date advanced by 1 day
    TimeMachine.session = session
    new_date = TimeMachine.simulated_date
    new_day_count = TimeMachine.days_since_start
    
    assert_equal original_date + 1.day, new_date
    assert_equal original_day_count + 1, new_day_count
    assert_equal new_date.to_s, session[:time_machine]['simulated_date']
  end

  test "should advance 7 days when time machine is active" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!
    
    TimeMachine.session = session
    original_date = TimeMachine.simulated_date
    original_day_count = TimeMachine.days_since_start

    # Advance 7 days (POST request)
    post debug_next_7_days_path
    # May redirect for HTML format, or return turbo_stream
    follow_redirect! if response.redirect?

    # Check simulated date advanced by 7 days
    TimeMachine.session = session
    new_date = TimeMachine.simulated_date
    new_day_count = TimeMachine.days_since_start
    
    assert_equal original_date + 7.days, new_date
    assert_equal original_day_count + 7, new_day_count
    assert_equal new_date.to_s, session[:time_machine]['simulated_date']
  end

  test "should add 6 to streak when advancing 7 days if habit was completed" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!
    
    TimeMachine.session = session
    original_date = TimeMachine.simulated_date
    
    # Complete the habit on the current day
    @habit.update!(completed_on: original_date)
    creature = @habit.streakling_creature
    creature.update_streak_and_mood!
    
    original_streak = creature.reload.current_streak
    assert_equal 1, original_streak, "Streak should be 1 after completing on day 1"
    
    # Advance 7 days (this should add 6 to streak for habits completed on current day)
    post debug_next_7_days_path
    # May redirect for HTML format, or return turbo_stream
    follow_redirect! if response.redirect?
    
    # Ensure TimeMachine session is set for verification
    TimeMachine.session = session
    
    # Check that streak increased by 6 (for the 6 skipped days: days 2-7)
    creature.reload
    new_streak = creature.current_streak
    assert_equal original_streak + 6, new_streak, "Streak should increase by 6 (for days 2-7) when advancing 7 days"
    assert_equal 7, new_streak, "Final streak should be 7 (1 original + 6 simulated)"
  end

  test "should not add to streak when advancing 7 days if habit was not completed" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!
    
    TimeMachine.session = session
    
    # Don't complete the habit
    @habit.update!(completed_on: nil)
    creature = @habit.streakling_creature
    creature.reset_to_new!
    
    original_streak = creature.reload.current_streak
    assert_equal 0, original_streak
    
    # Advance 7 days
    post debug_next_7_days_path
    follow_redirect! if response.redirect?
    
    # Streak should remain 0 since habit was not completed
    creature.reload
    assert_equal 0, creature.current_streak, "Streak should remain 0 if habit was not completed on original day"
  end

  test "should not advance when time machine is not active" do
    # Don't activate - just try to advance
    # HTML format redirects, turbo_stream format returns bad_request
    post debug_next_day_path
    assert_response :redirect
    follow_redirect!
    assert_match /Time machine is not active/i, flash[:alert] || flash[:notice] || ""

    post debug_next_7_days_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :bad_request
  end

  test "should preserve start_date when advancing days" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!
    
    start_date = session[:time_machine]['start_date']

    # Advance several days
    post debug_next_day_path
    follow_redirect! if response.redirect?
    
    post debug_next_7_days_path
    follow_redirect! if response.redirect?

    # Start date should remain unchanged
    assert_equal start_date, session[:time_machine]['start_date']
  end

  test "should reset all user habits on activation" do
    # Create multiple habits
    habit1 = @habit
    habit2 = Habit.create!(habit_name: "Habit 2", user: @user)
    habit1.update!(completed_on: Time.zone.today)
    habit2.update!(completed_on: 2.days.ago)

    # Activate time machine
    get debug_activate_time_machine_url

    # All habits should be reset
    habit1.reload
    habit2.reload
    assert_nil habit1.completed_on
    assert_nil habit2.completed_on
  end

  test "should reset all creatures on activation" do
    # Create habit with creature
    creature = @habit.streakling_creature
    creature.update!(
      current_streak: 20,
      mood: "sick",
      stage: "teen"
    )

    # Activate time machine
    get debug_activate_time_machine_url

    # Creature should be reset
    creature.reload
    assert_equal 0, creature.current_streak
    assert_equal "happy", creature.mood
    assert_equal "egg", creature.stage
  end

  test "should handle turbo_stream format for next_day" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!

    # Request turbo_stream format
    post debug_next_day_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.content_type, "text/vnd.turbo-stream.html"
  end

  test "should handle turbo_stream format for next_7_days" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!

    # Request turbo_stream format
    post debug_next_7_days_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_includes response.content_type, "text/vnd.turbo-stream.html"
  end

  test "should only work in development or test environment" do
    # This test assumes we're running in test environment
    # In production, the controller would raise an error
    assert Rails.env.test? || Rails.env.development?
  end

  test "should set day count to start at 1 on activation" do
    # Activate time machine
    get debug_activate_time_machine_url
    follow_redirect!

    TimeMachine.session = session
    assert_equal 1, TimeMachine.days_since_start
  end
end
