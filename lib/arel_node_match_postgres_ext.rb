module ArelExt
  module Visitors
    module PostgreSQL
      module InstanceMethods
        def self.included(base)
          base.class_eval do
            alias_method_chain :visit_Arel_Nodes_Matches, :format_sql92
            alias_method_chain :visit_Arel_Nodes_DoesNotMatch, :format_sql92
          end
        end
        def visit_Arel_Nodes_Matches_with_format_sql92 o, a
          collector = visit_Arel_Nodes_Matches_without_format_sql92(o, a)
          if o.escape
            collector << ' ESCAPE '
            visit o.escape, collector
          else
            collector
          end
        end

        def visit_Arel_Nodes_DoesNotMatch_with_format_sql92 o, a
          collector = visit_Arel_Nodes_DoesNotMatch_without_format_sql92(o, a)
          if o.escape
            collector << ' ESCAPE '
            visit o.escape, collector
          else
            collector
          end
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  Arel::Visitors::PostgreSQL.send(:include, ArelExt::Visitors::PostgreSQL::InstanceMethods)
end

