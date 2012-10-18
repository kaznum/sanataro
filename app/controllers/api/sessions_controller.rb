class Api::SessionsController < ApplicationController
  def create
    unless params[:session]
      render nothing: true, status: :unauthorized
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
      render nothing: true, status: :unauthorized
    end
  end

  def destroy
  end
end
