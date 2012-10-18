module ChartData
  def self.included(base)
    base.class_eval do
      include ChartData::InstanceMethods

      before_filter :required_login
      before_filter :redirect_if_invalid_year_month!
    end
  end

  module InstanceMethods
    private

    def redirect_if_invalid_year_month!
      unless CommonUtil.valid_combined_year_month?(params[:id])
        render status: :not_acceptable, text: "Not Acceptable"
        return
      end
      true
    end
  end
end
