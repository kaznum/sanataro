module Api
  module Auth
    def self.included(base)
      base.class_eval do
        before_filter :authenticate_via_api
        include Api::General
        include Api::Auth::InstanceMethods
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
            challenge_user = User.find_by_login_and_active(login, true)
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

  module General
    def self.included(base)
      base.class_eval do
        skip_before_filter :verify_authenticity_token
        after_filter :set_access_control_headers
        include Api::General::InstanceMethods
      end
    end

    module InstanceMethods
      def set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Request-Method'] = '*'
        headers["P3P"] = 'CP="UNI CUR OUR"'
      end
    end
  end
end
