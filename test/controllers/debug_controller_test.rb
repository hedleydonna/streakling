require "test_helper"

class DebugControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should get yesterday" do
    get debug_yesterday_url
    assert_response :redirect
  end

  test "should get kill" do
    get debug_kill_url
    assert_response :redirect
  end

  test "should get complete_today" do
    get debug_complete_today_url
    assert_response :redirect
  end

  test "should get reset" do
    get debug_reset_url
    assert_response :redirect
  end
end
