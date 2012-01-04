require 'test_helper'

class EntryCandidatesControllerTest < ActionController::TestCase
  fixtures :all
  def test_index_no_login
    xhr :get, :index, :item_name => 'i'
    assert_rjs :redirect_to, login_path
  end

  def test_index
    login

    # rack of params
    xhr :get, :index
    assert_response :success
    assert_template nil
  end
  
  def test_index_w_item_name
    login
    xhr :get, :index, :item_name => 't'
    assert_response :success
    assert_template '_candidate'
  end

end
