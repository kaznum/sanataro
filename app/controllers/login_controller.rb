# -*- coding: utf-8 -*-
class LoginController < ApplicationController
  before_filter :required_login, :except=>[:login, :do_login, :create_user, :do_create_user, :do_logout, :confirmation]

  def index
    redirect_to login_url
  end

  def do_login
    _do_login(params[:login], params[:password], params[:autologin], false, params[:only_add])
    if session[:user_id].nil?
      render_js_error :id => "warning", :default_message => t("error.user_or_password_is_invalid")
    else
      if params[:only_add]
        redirect_js_to simple_input_path
      else
        redirect_js_to current_entries_url
      end
    end
  end
  
  def do_logout
    unless session[:user_id].nil?
      autologin_key = cookies[:autologin]
      unless autologin_key.nil?
        k = AutologinKey.matched_key(session[:user_id], autologin_key)
        k.destroy unless k.nil?
      end
    end

    _clear_user_session
    _clear_cookies
    
    session[:disable_autologin] = true

    redirect_to login_url
  end


  def login
    if _force_show_login_and_succeeded? || _autologin_and_succeeded?
      return
    end
    render :layout=>'entries'
  end

  def _force_show_login_and_succeeded?
    if session[:disable_autologin]
      session[:disable_autologin] = false
      render :layout => 'entries'
      return true
    end
    
    false
  end
  
  def _autologin_and_succeeded?
    al_params = _get_autologin_params_from_cookies
    
    user = _get_user_by_login_and_autologin_key(al_params[:login], al_params[:autologin_key])
    if (not user.nil?)
      _do_login(user.login, nil, "1", true, al_params[:only_add])
      redirect_to (al_params[:only_add] ? simple_input_path : current_entries_url)
      return true
    end
    return false
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
    render "do_create_user"
  rescue ActiveRecord::RecordInvalid
    render_js_error :id => "warning", :errors => @user.errors, :default_message => ''
  end

  def _confirmation_key
    a_char = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(15){a_char[rand(a_char.size)]}.join    
  end

  def confirmation
    login = params[:login]
    sid = params[:sid]
    user = User.find_by_login_and_confirmation(login, sid)
    if user.nil?
      render 'confirmation_error', :layout => 'entries'
    else
      user.deliver_signup_complete
      user.update_attributes!(:active => true)
      account1 = user.accounts.create(:name => '財布', :order_no => 10, :account_type => 'account')
      account2 = user.accounts.create(:name => '銀行A', :order_no => 20, :account_type => 'account')
      account3 = user.accounts.create(:name => '銀行B', :order_no => 30, :account_type => 'account')
      account4_cr = user.accounts.create(:name => 'クレジットカード', :order_no => 40, :account_type => 'account')
      
      income1 = user.accounts.create(:name => '給与', :order_no => 10, :account_type => 'income')
      income2 = user.accounts.create(:name => '賞与', :order_no => 20, :account_type => 'income')
      income3 = user.accounts.create(:name => '雑収入', :order_no => 30, :account_type => 'income')
      
      outgo1 = user.accounts.create(:name => '食費', :order_no => 10, :account_type => 'outgo')
      outgo2 = user.accounts.create(:name => '光熱費', :order_no => 20, :account_type => 'outgo')
      outgo3 = user.accounts.create(:name => '住居費', :order_no => 30, :account_type => 'outgo')
      outgo4 = user.accounts.create(:name => '美容費', :order_no => 40, :account_type => 'outgo')
      outgo5 = user.accounts.create(:name => '衛生費', :order_no => 50, :account_type => 'outgo')
      outgo6 = user.accounts.create(:name => '雑費', :order_no => 60, :account_type => 'outgo')
      
      credit_relation = user.credit_relations.create(:credit_account_id => account4_cr.id, :payment_account_id => account3.id, :settlement_day => 25, :payment_month => 2, :payment_day => 4)
      
      item_income = user.items.create(:name => 'サンプル収入(消してかまいません)', :from_account_id => income3.id, :to_account_id => account1.id, :amount => 1000, :action_date => today)
      item_outgo = user.items.create(:name => 'サンプル(消してかまいません)', :from_account_id => account1.id, :to_account_id => outgo1.id, :amount => 250, :action_date => today, :tag_list => 'タグもOK')
      
      render :layout => 'entries'
    end
  end

  
  private
  
  def _do_login(login, password, set_autologin, is_autologin=false, is_only_add=false)
    user = User.find_by_login_and_active(login, true)

    unless is_autologin || _password_correct?(login, password, user)
      _clear_user_session
      return
    end
    
    if is_autologin
      # do nothing(自動ログインの場合は何もしない)
    elsif set_autologin == "1"
      key = _secret_key
      _store_cookies(user.login, key, is_only_add)
      user.autologin_keys.create!(:autologin_key => key)
    else
      _clear_cookies
    end

    AutologinKey.cleanup(user.id)
    _store_user_session(user)
  end

  def _password_correct?(login, password, user)
    user && CommonUtil.correct_password?(login + password, user.password)
  end

  def _secret_key
    a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    Array.new(16){a[rand(a.size)]}.join
  end

  def _store_user_session(user)
    session[:user_id] = user.id
    session[:from_date] = today.beginning_of_month
    session[:to_date] = today.end_of_month
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
