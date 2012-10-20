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
        (doorkeeper_token || request.authorization.present?) ? true : verified_request_without_condition?
      end
    end
  end
end
