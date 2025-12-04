require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @admin = users(:admin)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email should be downcased" do
    @user.email = "USER@EXAMPLE.COM"
    @user.save
    assert_equal "user@example.com", @user.reload.email
  end

  test "admin? should return true for admin users" do
    assert @admin.admin?
    assert_not @user.admin?
  end

  test "should have many habits" do
    assert_respond_to @user, :habits
  end

  test "should destroy associated habits when destroyed" do
    habit_count = @user.habits.count
    assert_difference "Habit.count", -habit_count do
      @user.destroy
    end
  end

  test "current_streak should default to 0" do
    user = User.new(email: "test@example.com", password: "password")
    assert_equal 0, user.current_streak
  end

  test "longest_streak should default to 0" do
    user = User.new(email: "test@example.com", password: "password")
    assert_equal 0, user.longest_streak
  end
end
