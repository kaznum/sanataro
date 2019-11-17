Doorkeeper.configure do
  # This block will be called to check whether the
  # resource owner is authenticated or not
  resource_owner_authenticator do |routes|
    # raise "Please configure doorkeeper resource_owner_authenticator block located in #{__FILE__}"
    # Put your resource owner authentication logic here.
    # If you want to use named routes from your app you need
    # to call them on routes object eg.
    # routes.new_user_session_path
    # e.g. User.find_by_id(session[:user_id]) || redirect_to(routes.new_user_session_url)
    User.find_by_id(session[:user_id]) || redirect_to(routes.login_url)
  end

  # If you want to restrict the access to the web interface for
  # adding oauth authorized applications you need to declare the
  # block below
  # admin_authenticator do |routes|
  #   # Put your admin authentication logic here.
  #   # If you want to use named routes from your app you need
  #   # to call them on routes object eg.
  #   # routes.new_admin_session_path
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(routes.new_admin_session_url)
  # end
  admin_authenticator do |routes|
    def authenticate
      admin_user, admin_password = get_correct_credential
      if admin_user.nil? || admin_password.nil?
        return nil
      end

      authenticate_or_request_with_http_basic do |username, password|
        username == admin_user && password == admin_password
      end
    end

    def get_correct_credential
      admin_user =  ENV['OAUTH_ADMIN_USER'].presence
      admin_password = ENV['OAUTH_ADMIN_PASSWORD'].presence

      begin
        admin_user ||= GlobalSettings.oauth_admin_user
        admin_password ||= GlobalSettings.oauth_admin_password
      rescue Settingslogic::MissingSetting
        admin_user = admin_password = nil
      end

      [admin_user, admin_password]
    end
    authenticate || render(text: 'Unauthorized', status: :unauthorized)
  end

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  # access_token_expires_in 2.hours

  # Issue access tokens with refresh token (disabled by default)
  # use_refresh_token

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  # default_scopes  :public
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from `HTTP_AUTHORIZATION` header and
  # fallsback to `:client_id` and `:client_secret` from `params` object
  # Check out the wiki for mor information on customization
  # client_credentials :from_basic, :from_params

end
