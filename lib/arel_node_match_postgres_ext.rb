# frozen_string_literal: true

module ArelExt
  module Visitors
    module PostgreSQL
      module InstanceMethods
        def visit_Arel_Nodes_Matches o, a
          collector = super
          if o.escape
            collector << ' ESCAPE '
            visit o.escape, collector
          else
            collector
          end
        end

        def visit_Arel_Nodes_DoesNotMatch o, a
          collector = super
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
  Arel::Visitors::PostgreSQL.prepend ArelExt::Visitors::PostgreSQL::InstanceMethods
end
