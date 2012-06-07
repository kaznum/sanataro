module Api
  def self.included(base)
    base.class_eval do
      include Api::InstanceMethods
      before_filter :redirect_if_invalid_year_month!
    end
  end

  module InstanceMethods
    private

    def json_date_format(date)
      date.to_time.to_i * 1000
    end

    def redirect_if_invalid_year_month!
      unless CommonUtil.valid_combined_year_month?(params[:id])
        redirect_to login_url
        return
      end
      true
    end
  end
end
