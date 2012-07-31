require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  test "should find a profile" do
    get :show, id: users(:jason).profile_name
    assert_response :success
    assert_template 'profiles/show'
  end

  test "should render a 404 on no profile found" do
    get :show, id: 'doesnt exist'
    assert_response :not_found
  end

  test "shows statuses on success" do
    get :show, id: users(:jason).profile_name
    assert_not_empty assigns(:statuses)
  end

  test "only shows the correct user's statuses" do
    get :show, id: users(:jason).profile_name
    assigns(:statuses).each do |status|
      assert_equal users(:jason), status.user
    end
  end


end
