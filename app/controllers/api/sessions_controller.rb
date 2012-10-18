class Api::SessionsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  after_filter :set_access_control_headers

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
      respond_to do |format|
        format.json { render json: {}, status: :ok }
        format.html { render text: "succeeded", status: :ok }
      end
    else
      render_when_not_login
    end
  end

  def destroy
    reset_session
    respond_to do |format|
      format.json { render json: {}, status: :ok }
      format.html { render text: "succeeded", status: :ok }
    end
  end

  private
  def render_when_not_login
    render nothing: true, status: :unauthorized
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
    headers["P3P"] = 'CP="IDC MON IVA SAM BUS FIN"'
  end

end
