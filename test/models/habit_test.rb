require "test_helper"

class HabitTest < ActiveSupport::TestCase
  setup do
    @habit = habits(:one)
    @user = users(:one)
  end

  test "should be valid" do
    assert @habit.valid?
  end

  test "habit_name should be present" do
    @habit.habit_name = ""
    assert_not @habit.valid?
  end

  test "should belong to user" do
    assert_respond_to @habit, :user
    assert_equal @user, @habit.user
  end

  test "should have one streakling_creature" do
    assert_respond_to @habit, :streakling_creature
  end

  test "completed_today? should return true when completed_on is today" do
    @habit.completed_on = Date.today
    assert @habit.completed_today?
  end

  test "completed_today? should return false when completed_on is not today" do
    @habit.completed_on = 1.day.ago
    assert_not @habit.completed_today?
  end

  test "completed_today? should return false when completed_on is nil" do
    @habit.completed_on = nil
    assert_not @habit.completed_today?
  end

  test "display_emoji should return habit emoji" do
    assert_equal "📝", @habit.display_emoji
  end

  test "should destroy associated streakling_creature when destroyed" do
    habit = Habit.create!(habit_name: "Test Habit", user: @user)
    creature = habit.streakling_creature

    assert_difference "StreaklingCreature.count", -1 do
      habit.destroy
    end
  end

  test "ensure_streakling_creature! should create creature if none exists" do
    # Create habit by deleting its existing creature
    habit = habits(:one)
    creature = habit.streakling_creature
    creature.destroy
    habit.reload

    assert_nil habit.streakling_creature

    habit.ensure_streakling_creature!
    assert_not_nil habit.streakling_creature
    assert_equal "Little One", habit.streakling_creature.streakling_name
    assert_equal "dragon", habit.streakling_creature.animal_type
  end

  test "ensure_streakling_creature! should not create duplicate creatures" do
    habit = habits(:one) # Already has a creature
    existing_creature = habit.streakling_creature

    assert_no_difference "StreaklingCreature.count" do
      habit.ensure_streakling_creature!
    end

    assert_equal existing_creature, habit.streakling_creature
  end

  test "after_create should automatically create streakling_creature" do
    assert_difference "StreaklingCreature.count", 1 do
      Habit.create!(habit_name: "New Habit", user: @user)
    end
  end
end
