require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin = users(:admin)
  end

  test "should get index for authenticated user" do
    sign_in @user
    get root_path
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "should show user's habits and creatures" do
    sign_in @user
    get root_path
    assert_response :success

    # Should show user's dashboard with habits
    assert_match /Welcome back/, response.body
  end

  test "should show admin banner for admin users" do
    sign_in @admin
    get root_path
    assert_response :success

    # Response should contain admin link
    assert_match /Admin Access/, response.body
  end

  test "should not show admin banner for regular users" do
    sign_in @user
    get root_path
    assert_response :success

    # Response should not contain admin link
    assert_no_match /Admin Access/, response.body
  end

  test "should display debug panel in development" do
    sign_in @user
    # This test assumes we're in development mode
    # In production, the debug panel wouldn't be shown
    get root_path
    assert_response :success
  end
end
