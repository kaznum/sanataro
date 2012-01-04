require 'test_helper'

class Settings::UsersControllerTest < ActionController::TestCase
  fixtures :all
  def test_show_no_login
    get :show
    assert_redirected_to login_path
  end
  
  def test_show
    login
    
    get :show, :lang => 'en'
    assert_response :success
    assert_template 'show'
    assert_tag :tag=>'div', :attributes=>{:id=>'input_area'}
    assert_tag :tag=>'form', :parent => {:tag=>'div', :attributes=>{ :id => 'input_area' }}, :attributes => {:action => settings_user_path}
    assert_tag :tag=>'input', :attributes=>{:name=>'email', :type=>'text', :value => users(:user1).email } , :ancestor => {:tag=>'form'}
    assert_tag :tag=>'input', :attributes=>{:name=>'password_plain', :type=>'password' } , :ancestor => {:tag=>'form'}
    assert_tag :tag=>'input', :attributes=>{:name=>'password_confirmation', :type=>'password' }, :ancestor => {:tag=>'form'}
    assert_tag :tag=>'input', :attributes=>{:type=>'submit', :id=>'change_button'}, :ancestor => {:tag=>'form'}
    assert_tag :tag=>'span', :attributes=>{:id=>'warning', :class=>'warning'}, :ancestor => {:tag=>'div', :attributes=>{:id=>'input_area'}}

    assert_tag :tag=>'a', :attributes => {:href => /#{Regexp.escape(logout_path)}/ }

    assert_valid_markup
  end
  
  def test_update_no_login
    old_user1 = users(:user1)
    xhr :put, :update
    assert_select_rjs :redirect, login_path
  end
  
  def test_update_invalid_method_put
    old_user1 = users(:user1)
    login
    put :update, :password_plain=>'1234567', :password_confirmation=>'1234567'
    assert_redirected_to login_path
  end
  def test_update_invalid_method_post
    post :update, :password_plain=>'1234567', :password_confirmation=>'1234567'
    assert_redirected_to login_path
  end
  
  def test_update
    old_user1 = users(:user1)
    login
    xhr :put, :update, :password_plain=>'1234567', :password_confirmation=>'1234567', :email => 'hogehoge@example.com'
    assert_select_rjs :replace_html, "input_area"

    new_user1 = User.find(users(:user1).id)
    assert_not_equal old_user1.password, new_user1.password
    assert_equal new_user1.id, session[:user_id]
    assert_equal User.find(session[:user_id]).password, new_user1.password
    assert_equal User.find(session[:user_id]).email, new_user1.email
    assert CommonUtil.check_password('user11234567', new_user1.password)
  end
  
  def test_update_no_password
    old_user1 = users(:user1)
    login
    xhr :put, :update, :password_plain=>'', :password_confirmation=>'', :email => 'hogehoge@example.com'
    assert_select_rjs :replace_html, "input_area"
    
    new_user1 = User.find(users(:user1).id)
    assert (not new_user1.password.blank?)
    assert_equal old_user1.password, new_user1.password
    assert_equal 'hogehoge@example.com', new_user1.email
    assert_equal User.find(session[:user_id]).password, new_user1.password
    assert_equal User.find(session[:user_id]).email, new_user1.email
  end

  def test_update_error_password_not_same
    old_user1 = users(:user1)
    login
    xhr :put, :update, :password_plain=>'1234567', :password_confirmation=>'', :email => 'hogehoge@example.com'
    
    assert_select_rjs :replace_html, "warning", /Password/
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
    assert_no_rjs :replace_html, "input_area"
  end
  
  def test_update_error_password_email_invalid
    old_user1 = users(:user1)
    login
    xhr :put, :update, :password_plain=>'1234567', :password_confirmation=>'1234567', :email => 'sll'
    new_user1 = User.find(old_user1.id)
    
    assert_select_rjs :replace_html, "warning", /Email/
    assert_rjs :visual_effect, :pulsate, :warning, :duration => '1.0'
    assert_no_rjs :replace_html, :input_area
    assert_equal old_user1.email, new_user1.email
    assert_equal old_user1.email, new_user1.email
  end
end
