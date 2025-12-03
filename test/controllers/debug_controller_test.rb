require "test_helper"

class DebugControllerTest < ActionDispatch::IntegrationTest
  test "should get yesterday" do
    get debug_yesterday_url
    assert_response :success
  end

  test "should get kill" do
    get debug_kill_url
    assert_response :success
  end

  test "should get complete_today" do
    get debug_complete_today_url
    assert_response :success
  end

  test "should get reset" do
    get debug_reset_url
    assert_response :success
  end
end
