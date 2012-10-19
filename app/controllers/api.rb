module Api
  module Auth
    def self.included(base)
      base.class_eval do
        doorkeeper_for :all, if: -> { request.authorization.blank? && !session[:user_id] }
        before_filter :authenticate_via_api
        include Api::General
        include Api::Auth::InstanceMethods
      end
    end

    module InstanceMethods
      def authenticate_via_api
        if doorkeeper_token
          # for OAuth
          user = User.find_by_id_and_active(doorkeeper_token.resource_owner_id,true)
        elsif session[:user_id]
          # for Web Browser login
          user = User.find_by_id_and_active(session[:user_id],true)
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
          render text: "You do not have the permission to access this resource.", status: :unauthorized
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
