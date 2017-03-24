require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  test 'GET to home' do
    get pages_home_url
    assert_response :success
  end

end
