class Api::SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    unless params[:session]
      render_when_not_login
      return
    end

    login = params[:session][:login]
    password = params[:session][:password]

    user = User.find_by_login_and_active(login, true)

    if user && user.password_correct?(password)
      authenticated = true
    end

    if authenticated
      session[:user_id] = user.id
      render nothing: true, status: :ok
    else
      render_when_not_login
    end
  end

  def destroy
    reset_session
    render nothing: true, status: :ok
  end

  private
  def render_when_not_login
    render nothing: true, status: :unauthorized
  end

end
