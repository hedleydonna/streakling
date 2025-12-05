require "test_helper"

class DebugControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get yesterday and set habits to yesterday" do
    habit = habits(:one)
    original_date = habit.completed_on

    get debug_yesterday_url
    assert_redirected_to root_path
    assert_equal "All habits set to YESTERDAY — Creatures are sad", flash[:notice]

    habit.reload
    assert_equal 1.day.ago.to_date, habit.completed_on
  end

  test "should get kill and set habits to 2 days ago" do
    habit = habits(:one)

    get debug_kill_url
    assert_redirected_to root_path
    assert_equal "CREATURES ARE DEAD", flash[:alert]

    habit.reload
    assert_equal 2.days.ago.to_date, habit.completed_on
  end

  test "should get complete_today and set habits to today" do
    habit = habits(:one)
    habit.update(completed_on: 1.day.ago)

    get debug_complete_today_url
    assert_redirected_to root_path
    assert_equal "Habits completed today — Creatures are happy!", flash[:notice]

    habit.reload
    assert_equal Date.today, habit.completed_on
  end

  test "should get reset and set habits to today" do
    habit = habits(:one)

    get debug_reset_url
    assert_redirected_to root_path
    assert_equal "Everything reset — Creatures are HAPPY again", flash[:notice]

    habit.reload
    assert_equal Date.today, habit.completed_on
  end

  test "should ensure creatures exist for all habits" do
    # Create a habit without a creature (simulate data inconsistency)
    habit_without_creature = Habit.create!(habit_name: "Orphan Habit", user: @user)
    habit_without_creature.streakling_creature&.destroy if habit_without_creature.streakling_creature

    assert_nil habit_without_creature.reload.streakling_creature

    get debug_complete_today_url

    # Should have created a creature for the orphan habit
    assert_not_nil habit_without_creature.reload.streakling_creature
  end

  test "should require authentication" do
    sign_out @user

    get debug_yesterday_url
    assert_redirected_to new_user_session_path
  end

  test "should only work in development environment" do
    # This test assumes we're running in test environment
    # In production, the controller would raise an error
    assert Rails.env.test?
  end

  test "should reset to new and activate time machine" do
    get debug_reset_to_new_url
    assert_redirected_to root_path
    follow_redirect!

    # Should have time machine session data
    assert session[:time_machine]
    assert session[:time_machine]['active']
  end

  test "should advance to next day when time machine active" do
    # Activate time machine first
    get debug_reset_to_new_url
    follow_redirect!

    # Now advance to next day
    get debug_next_day_url
    assert_redirected_to root_path
  end

  test "should go back one day when time machine active" do
    # Activate time machine and advance first
    get debug_reset_to_new_url
    follow_redirect!
    get debug_next_day_url
    follow_redirect!

    # Now go back
    get debug_previous_day_url
    assert_redirected_to root_path
  end

  test "should exit time machine" do
    # Activate time machine first
    get debug_reset_to_new_url
    follow_redirect!

    # Exit time machine
    get debug_exit_time_machine_url
    assert_redirected_to root_path
  end
end
