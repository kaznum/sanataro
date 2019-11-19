# frozen_string_literal: true
module MonthlyReports
  def self.included(base)
    base.class_eval do
      include ::MonthlyReports::InstanceMethods

      before_action :required_login
    end
  end

  module InstanceMethods
  end
end
