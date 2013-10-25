module ActiveRecordExt
  module ErrorSupport
    module InstanceMethods
      def error_messages
        message.split(",").map(&:strip)
      end
    end
  end
end

module ArelExt
  module Visitors
    module ToSql
      module InstanceMethods
        def self.included(base)
          base.class_eval do
            alias_method_chain :visit_Arel_Nodes_Matches, :format_sql92
            alias_method_chain :visit_Arel_Nodes_DoesNotMatch, :format_sql92
          end
        end
        def visit_Arel_Nodes_Matches_with_format_sql92 o, a
          visit_Arel_Nodes_Matches_without_format_sql92(o, a) + " ESCAPE '!'"
        end

        def visit_Arel_Nodes_DoesNotMatch_with_format_sql92 o, a
          visit_Arel_Nodes_DoesNotMatch_without_format_sql92(o, a) + " ESCAPE '!'"
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::RecordInvalid.send(:include, ActiveRecordExt::ErrorSupport::InstanceMethods)
  Arel::Visitors::ToSql.send(:include, ArelExt::Visitors::ToSql::InstanceMethods)
  Arel::Visitors::PostgreSQL.send(:include, ArelExt::Visitors::ToSql::InstanceMethods)
end
