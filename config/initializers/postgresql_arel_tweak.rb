#
# This is the temporary tweak for PostgreSQL "order by" with arel.
#
# https://github.com/rails/rails/issues/5868
#
ActiveSupport.on_load(:active_record) do
  module ActiveRecord
    module ConnectionAdapters
      PostgreSQLAdapter = Class.new(AbstractAdapter) unless const_defined?(:PostgreSQLAdapter)
      PostgreSQLAdapter.class_eval do
        def distinct(columns, orders) #:nodoc:
          return "DISTINCT #{columns}" if orders.empty?

          # Construct a clean list of column names from the ORDER BY clause, removing
          # any ASC/DESC modifiers
          # order_columns = orders.collect { |s| s.gsub(/\s+(ASC|DESC)\s*/i, '') }
          order_columns = orders.collect { |s| (s.respond_to?(:to_sql) ? s.to_sql : s).gsub(/\s+(ASC|DESC)\s*/i, '') }
          order_columns.delete_if { |c| c.blank? }
          order_columns = order_columns.zip((0...order_columns.size).to_a).map { |s,i| "#{s} AS alias_#{i}" }

          "DISTINCT #{columns}, #{order_columns * ', '}"
        end
      end
    end
  end
end
