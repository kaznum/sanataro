# -*- coding: utf-8 -*-
class LoginController < ApplicationController
  before_filter :required_login, :except=>[:login, :do_login, :create_user, :do_create_user, :do_logout, :confirmation]
  before_filter :_render_login_if_forced!, only: [:login]
  before_filter :_autologin_if_required!, only: [:login]

  def index
    redirect_to login_url
  end

  def login
    if session[:user_id]
      redirect_to current_entries_url
    else
      render :layout=>'entries'
    end
  end

  def do_login
    _do_login(params[:login], params[:password], params[:autologin], false, params[:only_add])
    unless session[:user_id]
      render_js_error :id => "warning", :default_message => t("error.user_or_password_is_invalid")
      return
    end

    redirect_js_to params[:only_add] ? simple_input_url : current_entries_url
  end

  def do_logout
    if session[:user_id]
      autologin_key = cookies[:autologin]
      if autologin_key
        k = AutologinKey.matched_key(session[:user_id], autologin_key)
        k.try(:destroy)
      end
    end

    _clear_user_session
    _clear_cookies
    session[:disable_autologin] = true

    redirect_to login_url
  end

  def create_user
    render :layout => 'entries'
  end

  def do_create_user
    @user = User.new do |user|
      user.login = params[:login].strip
      user.password_plain = params[:password_plain]
      user.password_confirmation = params[:password_confirmation]
      user.email = params[:email].strip
      user.confirmation = _confirmation_key
      user.active = false
    end
    @user.save!

    @user.deliver_signup_confirmation
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "warning", :errors => @user.errors, :default_message => ''
  end

  def confirmation
    login = params[:login]
    sid = params[:sid]
    user = User.find_by_login_and_confirmation(login, sid)
    unless user
      render 'confirmation_error', :layout => 'entries'
      return
    end

    user.deliver_signup_complete
    user.update_attributes!(:active => true)
    user.store_sample
    render :layout => 'entries'
  end

  private

  def _confirmation_key
    a_char = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(15){a_char[rand(a_char.size)]}.join
  end

  def _render_login_if_forced!
    if session[:disable_autologin]
      session[:disable_autologin] = false
      render :layout => 'entries'
      false
    else
      true
    end
  end

  def _autologin_if_required!
    al_params = _get_autologin_params_from_cookies

    user = _get_user_by_login_and_autologin_key(al_params[:login], al_params[:autologin_key])
    if user
      _do_login(user.login, nil, "1", true, al_params[:only_add])
      redirect_to (al_params[:only_add] ? simple_input_url : current_entries_url)
      false
    else
      true
    end
  end

  def _get_autologin_params_from_cookies
    login = cookies[:user]
    autologin_key = cookies[:autologin]
    only_add = cookies[:only_add]
    { :login => login, :autologin_key => autologin_key, :only_add => only_add }
  end

  def _get_user_by_login_and_autologin_key(login, autologin_key)
    user = (login.blank? || autologin_key.blank?) ? nil : User.find_by_login_and_active(login, true)
    matched_autologin_key = (user ? AutologinKey.matched_key(user.id, autologin_key) : nil)
    matched_autologin_key ? user : nil
  end

  def _do_login(login, password, set_autologin, is_autologin=false, is_only_add=false)
    user = User.find_by_login_and_active(login, true)

    unless user && (is_autologin || user.password_correct?(password))
      _clear_user_session
      return
    end

    if is_autologin
      # do nothing
    elsif set_autologin == "1"
      key = _secret_key
      _store_cookies(user.login, key, is_only_add)
      user.autologin_keys.create!(:autologin_key => key)
    else
      _clear_cookies
    end

    AutologinKey.cleanup
    _store_user_session(user)
  end

  def _secret_key
    a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(16){a[rand(a.size)]}.join
  end

  def _store_user_session(user)
    session[:user_id] = user.id
  end

  def _clear_user_session
      session[:user_id] = nil
  end

  def _store_cookies(login, key, is_only_add)
    cookies[:user] = { :value => login, :expires => 1.year.from_now }
    cookies[:autologin] = { :value => key, :expires => 1.year.from_now }
    if is_only_add
      cookies[:only_add] = { :value => '1', :expires => 1.year.from_now }
    else
      cookies.delete :only_add
    end
  end

  def _clear_cookies
    cookies.delete :user
    cookies.delete :autologin
    cookies.delete :only_add
  end
end
