module MonthlyReports
  def self.included(base)
    base.class_eval do
      include ::MonthlyReports::InstanceMethods

      before_filter :required_login
    end
  end

  module InstanceMethods
  end
end
