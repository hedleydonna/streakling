require "test_helper"

class HabitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @habit = habits(:one)
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get habits_url
    assert_response :success
  end

  test "should get new" do
    get new_habit_url
    assert_response :success
  end

  test "should create habit" do
    assert_difference("Habit.count") do
      assert_difference("StreaklingCreature.count") do
        post habits_url, params: {
          habit: {
            habit_name: "New Test Habit",
            description: "A test habit description",
            user_id: @user.id
          }
        }
      end
    end

    assert_redirected_to dashboard_path
    # Verify the habit has a streakling creature
    assert_not_nil Habit.last.streakling_creature
  end

  test "should create habit with creature customization" do
    assert_difference("Habit.count") do
      assert_difference("StreaklingCreature.count") do
        post habits_url, params: {
          habit: {
            habit_name: "Custom Habit",
            description: "Custom description",
            user_id: @user.id,
            streakling_creature_attributes: {
              streakling_name: "Custom Name",
              animal_type: "phoenix"
            }
          }
        }
      end
    end

    habit = Habit.last
    creature = habit.streakling_creature
    assert_equal "Custom Name", creature.streakling_name
    assert_equal "phoenix", creature.animal_type
  end

  test "should show habit" do
    get habit_url(@habit)
    assert_response :success
  end

  test "should get edit" do
    get edit_habit_url(@habit)
    assert_response :success
  end

  test "should update habit" do
    patch habit_url(@habit), params: {
      habit: {
        habit_name: "Updated Habit",
        description: "Updated description"
      }
    }
    assert_redirected_to dashboard_path

    @habit.reload
    assert_equal "Updated Habit", @habit.habit_name
  end

  test "should update habit and creature" do
    patch habit_url(@habit), params: {
      habit: {
        habit_name: "Updated Habit",
        streakling_creature_attributes: {
          id: @habit.streakling_creature.id,
          streakling_name: "Updated Name"
        }
      }
    }
    assert_redirected_to dashboard_path

    @habit.reload
    assert_equal "Updated Name", @habit.streakling_creature.streakling_name
  end

  test "should destroy habit and creature" do
    assert_difference("Habit.count", -1) do
      assert_difference("StreaklingCreature.count", -1) do
        delete habit_url(@habit)
      end
    end

    assert_redirected_to root_path
  end

  test "should toggle habit completion" do
    assert @habit.completed_today?  # Fixture habit is completed today

    patch toggle_habit_url(@habit), as: :turbo_stream
    assert_response :success

    @habit.reload
    assert_not @habit.completed_today?  # Should toggle to uncompleted
  end

  test "should require authentication" do
    sign_out @user

    get habits_url
    assert_redirected_to new_user_session_path

    get new_habit_url
    assert_redirected_to new_user_session_path

    post habits_url, params: { habit: { habit_name: "Test" } }
    assert_redirected_to new_user_session_path
  end

  test "should not allow accessing other users' habits" do
    other_user = users(:two)
    other_habit = habits(:three)

    get habit_url(other_habit)
    assert_redirected_to root_path
    assert_equal "You can only access your own habits.", flash[:alert]
  end
end
