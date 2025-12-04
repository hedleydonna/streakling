require "application_system_test_case"

class HabitsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @habit = habits(:one)
  end

  test "visiting the dashboard shows habits" do
    sign_in @user
    visit root_path
    assert_selector "h1", text: "Streakland Dashboard"
  end

  test "should create habit with creature" do
    sign_in @user
    visit root_path

    # Navigate to new habit page
    click_link "New Habit"

    fill_in "Habit Name", with: "Test System Habit"
    fill_in "Description", with: "A habit created by system test"
    fill_in "Streakling Name", with: "System Creature"
    choose "animal_phoenix" # Select phoenix

    click_button "Create Habit & Creature"

    assert_text "Habit & Creature were successfully created"
    assert_current_path habits_path
  end

  test "should toggle habit completion" do
    sign_in @user
    visit root_path

    # Find the habit card and click toggle
    within ".bg-white.rounded-3xl" do
      click_button "Complete Today"
    end

    # Should show success message via turbo stream
    assert_text "Habit completed!"
  end

  test "should show creature evolution" do
    sign_in @user
    visit root_path

    # Check that creature information is displayed
    assert_text "Spark" # Creature name from fixture
    assert_text "🐉" # Dragon emoji
  end

  test "should handle authentication" do
    visit root_path
    assert_current_path new_user_session_path

    sign_in @user
    visit root_path
    assert_current_path root_path
  end
end
