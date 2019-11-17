class Api::SessionsController < ApplicationController
  include Api::General

  respond_to :json

  def create
    unless params[:session]
      render_when_not_login
      return
    end

    login = params[:session][:login]
    password = params[:session][:password]

    user = User.find_by_login_and_active(login, true)

    authenticated = true if user && user.password_correct?(password)

    if authenticated
      session[:user_id] = user.id
      render json: { authenticity_token: form_authenticity_token }.to_json, status: :ok
    else
      render_when_not_login
    end
  end

  def destroy
    reset_session
    render json: {}, status: :ok
  end

  private

  def render_when_not_login
    render nothing: true, status: :unauthorized
  end
end
