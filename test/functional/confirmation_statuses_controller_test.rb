require 'test_helper'

class ConfirmationStatusesControllerTest < ActionController::TestCase
  fixtures :all
  def test_show_no_login
    xhr :get, :show
    assert_rjs :redirect_to, login_path
  end
  
  def test_show
    login
    xhr :get, :show
    assert (not assigns(:entries).empty?)
#    assert_rjs :hide, :confirmation_status
    assert_rjs :replace_html, :confirmation_status
#    assert_rjs :show, :confirmation_status
#    assert_rjs :visual_effect, :appear, :confirmation_status, :duration => '0.3'
    assert_rjs :visual_effect, :slide_down, :confirmation_status_body, :duration => '0.2'
    assert_template '_show'
  end

  def test_destroy_no_login
    xhr :delete, :destroy
    assert_rjs :redirect_to, login_path
  end
  def test_destroy
    login
    xhr :delete, :destroy
    assert_rjs :visual_effect, :slide_up, :confirmation_status_body, :duration => '0.2'
    assert_rjs :replace_html, :confirmation_status
    assert_template '_show_blank'
  end
end
