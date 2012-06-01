module ActiveRecordExt
  module ErrorSupport
    module InstanceMethods
      def error_messages
        message.split(",").map(&:strip)
      end
    end
  end
end
ActiveSupport.on_load(:active_record) do
  ActiveRecord::RecordInvalid.send(:include, ActiveRecordExt::ErrorSupport::InstanceMethods)
end
