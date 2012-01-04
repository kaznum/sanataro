require 'test_helper'

class Admin::UsersControllerTest < ActionController::TestCase
  fixtures :all
  def test_index
    get :index
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:users)
  end
  
end
