module MonthlyReports
  def self.included(base)
    base.class_eval do
      include ::MonthlyReports::InstanceMethods

      before_filter :required_login
      before_filter :redirect_if_id_is_blank!, only: :show
    end
  end

  module InstanceMethods
    private
    def redirect_if_id_is_blank!
      if params[:id].blank?
        redirect_js_to login_url
        return
      end
      true
    end
  end
end
