require 'active_record/validations'

module ActiveRecord
  module Sanataro
    module ErrorSupport
      def error_messages
        message.split(",").map(&:strip)
      end
    end
  end
end

ActiveRecord::RecordInvalid.send(:include, ActiveRecord::Sanataro::ErrorSupport)

