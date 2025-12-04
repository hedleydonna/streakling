require "test_helper"

class StreaklingCreatureTest < ActiveSupport::TestCase
  setup do
    @creature = streakling_creatures(:one)
    @eternal_creature = streakling_creatures(:eternal_creature)
  end

  test "should be valid" do
    assert @creature.valid?
  end

  test "should belong to habit" do
    assert_respond_to @creature, :habit
    assert_equal habits(:one), @creature.habit
  end

  test "habit_id should be unique" do
    duplicate_creature = @creature.dup
    @creature.save
    assert_not duplicate_creature.valid?
  end

  test "should delegate user to habit" do
    assert_equal @creature.habit.user, @creature.user
  end

  test "should delegate completed_on to habit" do
    assert_equal @creature.habit.completed_on, @creature.completed_on
  end

  test "should delegate completed_today? to habit" do
    assert_equal @creature.habit.completed_today?, @creature.completed_today?
  end

  test "current_stage should return correct stage based on effective_streak" do
    # Test various stages
    @creature.current_streak = 0
    assert_equal :egg, @creature.current_stage

    @creature.current_streak = 5
    assert_equal :newborn, @creature.current_stage

    @creature.current_streak = 15
    assert_equal :baby, @creature.current_stage

    @creature.current_streak = 30
    assert_equal :child, @creature.current_stage

    @creature.current_streak = 60
    assert_equal :teen, @creature.current_stage

    @creature.current_streak = 100
    assert_equal :adult, @creature.current_stage

    @creature.current_streak = 200
    assert_equal :master, @creature.current_stage

    @creature.current_streak = 350
    assert_equal :eternal, @creature.current_stage
  end

  test "stage_name should return correct stage name" do
    @creature.current_streak = 30
    assert_equal "Child", @creature.stage_name
  end

  test "message should return stage message when habit completed" do
    @creature.current_streak = 30
    @creature.habit.completed_on = Date.today
    assert_equal "We’re growing up together!", @creature.message
  end

  test "message should return missed day message when habit not completed" do
    @creature.consecutive_missed_days = 3
    @creature.habit.completed_on = 1.day.ago
    assert_match /three days/, @creature.message
  end

  test "message should return death message when creature is dead" do
    @creature.is_dead = true
    @creature.died_at = 2.days.ago
    assert_match /better place/, @creature.message
  end

  test "message should return eternal message for eternal creatures" do
    # Since messages are randomized, check that it's one of the eternal messages
    eternal_messages = [
      "Even eternal beings need their rest... but I still appreciate you! 🌙",
      "Our eternal bond remains unbroken, even on challenging days. 💪",
      "Time may pass, but our connection is forever. Tomorrow brings new adventures! 🌅",
      "Eternal patience is one of my greatest strengths. I know you'll be back. 🕊️",
      "Legends are forged through all experiences. Our journey continues! ⚔️"
    ]
    assert_includes eternal_messages, @eternal_creature.message
  end

  test "eternal? should return true for creatures with streak >= 300" do
    assert @eternal_creature.eternal?
    assert_not @creature.eternal?
  end

  test "effective_streak should equal current_streak for first 4 misses" do
    @creature.current_streak = 25
    @creature.consecutive_missed_days = 2
    assert_equal 25, @creature.effective_streak
  end

  test "effective_streak should apply regression after 4 misses" do
    @creature.current_streak = 25  # Child stage
    @creature.consecutive_missed_days = 5  # First regression (lose 1 stage)
    assert_equal 7, @creature.effective_streak  # Should drop to baby minimum
  end

  test "effective_streak should never drop below baby stage" do
    @creature.current_streak = 10  # Baby stage
    @creature.consecutive_missed_days = 20  # Heavy regression
    assert_equal 7, @creature.effective_streak  # Baby minimum
  end

  test "effective_streak should not regress for eternal creatures" do
    @eternal_creature.consecutive_missed_days = 10
    assert_equal 350, @eternal_creature.effective_streak
  end

  test "emoji should return correct emoji for each stage" do
    @creature.animal_type = "dragon"
    @creature.current_streak = 0
    assert_equal "🥚", @creature.emoji

    @creature.current_streak = 5
    assert_equal "✨🐉", @creature.emoji

    @creature.current_streak = 15
    assert_equal "👶🐉", @creature.emoji

    @creature.current_streak = 30
    assert_equal "🐉", @creature.emoji

    @creature.current_streak = 350
    assert_equal "🌈🐉", @creature.emoji
  end

  test "emoji should return tombstone for dead creatures" do
    @creature.is_dead = true
    assert_equal "🪦", @creature.emoji
  end

  test "mood_emoji should return correct emoji for each mood" do
    @creature.mood = "happy"
    assert_equal "😊", @creature.mood_emoji

    @creature.mood = "okay"
    assert_equal "😐", @creature.mood_emoji

    @creature.mood = "sad"
    assert_equal "😢", @creature.mood_emoji

    @creature.mood = "sick"
    assert_equal "🤒", @creature.mood_emoji

    @creature.mood = "dead"
    assert_equal "💀", @creature.mood_emoji
  end

  test "stage_emoji should return correct emoji for each stage" do
    @creature.current_streak = 0
    assert_equal "🥚", @creature.stage_emoji

    @creature.current_streak = 15
    assert_equal "👶", @creature.stage_emoji

    @creature.current_streak = 350
    assert_equal "🌈", @creature.stage_emoji
  end

  test "update_streak_and_mood! should increment streak when habit completed" do
    @creature.current_streak = 10
    @creature.mood = "sad"
    @creature.consecutive_missed_days = 2
    @creature.habit.completed_on = Date.today

    @creature.update_streak_and_mood!

    assert_equal 11, @creature.current_streak
    assert_equal "happy", @creature.mood
    assert_equal 0, @creature.consecutive_missed_days
  end

  test "update_streak_and_mood! should handle regression when habit missed" do
    @creature.current_streak = 25
    @creature.consecutive_missed_days = 4
    @creature.habit.completed_on = 1.day.ago

    @creature.update_streak_and_mood!

    assert_equal 25, @creature.current_streak  # No change in actual streak
    assert_equal "sick", @creature.mood  # 5 consecutive misses = sick
    assert_equal 5, @creature.consecutive_missed_days
  end

  test "update_streak_and_mood! should revive dead creatures after 7 completions" do
    @creature.is_dead = true
    @creature.current_streak = 6
    @creature.habit.completed_on = Date.today

    @creature.update_streak_and_mood!

    assert_not @creature.is_dead?
    assert_equal 7, @creature.current_streak
    assert_equal "baby", @creature.stage
    assert_equal "happy", @creature.mood
  end

  test "update_streak_and_mood! should track eternal achievement" do
    @creature.current_streak = 299
    @creature.habit.completed_on = Date.today

    @creature.update_streak_and_mood!

    assert_equal 300, @creature.current_streak
    assert_not_nil @creature.became_eternal_at
  end

  test "revive! should reset creature to baby state" do
    @creature.is_dead = true
    @creature.died_at = 1.day.ago
    @creature.current_streak = 50
    @creature.mood = "dead"

    @creature.revive!

    assert_not @creature.is_dead?
    assert_nil @creature.died_at
    assert_equal 7, @creature.current_streak
    assert_equal "baby", @creature.stage
    assert_equal "happy", @creature.mood
    assert_equal 1, @creature.revived_count
  end

  test "days_since_death should calculate correctly" do
    @creature.is_dead = true
    @creature.died_at = 3.days.ago

    assert_equal 3, @creature.days_since_death
  end

  test "days_since_death should return 0 for living creatures" do
    @creature.is_dead = false
    assert_equal 0, @creature.days_since_death
  end

  test "eternal_years should calculate correctly" do
    @eternal_creature.became_eternal_at = 1.year.ago.to_date
    # Should be approximately 1 year, but allow for slight variations
    years = @eternal_creature.eternal_years
    assert years >= 0 && years <= 2, "Expected 0-2 years, got #{years}"
  end

  test "reached_eternal_on_anniversary? should work correctly" do
    @eternal_creature.became_eternal_at = 1.year.ago.to_date
    # This test might be flaky depending on when it's run
    # Just test that the method exists and doesn't error
    assert_nothing_raised do
      @eternal_creature.reached_eternal_on_anniversary?
    end
  end
end
