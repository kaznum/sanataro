module Api
  def self.included(base)
    base.class_eval do
      skip_before_filter :verify_authenticity_token
      before_filter :authenticate_via_api
      include Api::InstanceMethods
    end
  end

  module InstanceMethods
    def authenticate_via_api
      # for Web Browser login
      if session[:user_id]
        user = User.find_by_id(session[:user_id])
      else
        # for Basic Auth login
        user = authenticate_with_http_basic { |login, password|
          challenge_user = User.find_by_login(login)
          challenge_user && challenge_user.password_correct?(password) ? challenge_user : nil
        }
      end

      if user
        @user = user
        true
      else
        render text: "You do not have the permission to access this resource.", status: :forbidden
        false
      end
    end
  end
end

