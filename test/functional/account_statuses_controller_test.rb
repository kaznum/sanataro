require 'test_helper'

class AccountStatusesControllerTest < ActionController::TestCase
  fixtures :all
  def test_show
    xhr :get, :show
    assert_rjs :redirect_to, login_path

    login

    xhr :get, :show
#    assert_rjs :hide, :account_status
    assert_rjs :replace_html, :account_status
    assert_rjs :visual_effect, :slide_down, :account_status_body, :duration => '0.2'
    assert_template '_index'
  end

  def test_destroy
    xhr :delete, :destroy
    assert_rjs :redirect_to, login_path

    login

    xhr :delete, :destroy
#    assert_rjs :hide, :account_status
    assert_rjs :visual_effect, :slide_up, :account_status_body, :duration => '0.2'
    assert_rjs :replace_html, :account_status
    assert_template 'entries/_account_status_blank'
  end
end
