module Api
  def self.included(base)
    base.class_eval do
      include Api::InstanceMethods

      before_filter :required_login
      before_filter :redirect_if_invalid_year_month!
    end
  end

  module InstanceMethods
    private

    def redirect_if_invalid_year_month!
      unless CommonUtil.valid_combined_year_month?(params[:id])
        redirect_to login_url
        return
      end
      true
    end
  end
end
