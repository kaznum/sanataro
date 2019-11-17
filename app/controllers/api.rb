module Api
  module Auth
    def self.included(base)
      base.class_eval do
        before_action :doorkeeper_authorize!, if: -> { request.authorization.blank? && !session[:user_id] }
        before_action :authenticate_via_api
        include Api::General
        include Api::Auth::InstanceMethods
      end
    end

    module InstanceMethods
      def authenticate_via_api
        if GlobalSettings.api_auth.oauth && doorkeeper_token
          # for OAuth
          user = User.find_by_id_and_active(doorkeeper_token.resource_owner_id, true)
        elsif GlobalSettings.api_auth.session && session[:user_id]
          # for Web Browser login
          user = User.find_by_id_and_active(session[:user_id], true)
        elsif GlobalSettings.api_auth.basic
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
        include Api::General::InstanceMethods
        alias_method_chain :verified_request?, :condition
      end
    end

    module InstanceMethods
      # override the method which checks CSRF token.
      def verified_request_with_condition?
        doorkeeper_token || request.authorization.present? || verified_request_without_condition?
      end
    end
  end
end
