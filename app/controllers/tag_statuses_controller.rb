class TagStatusesController < ApplicationController
  before_filter :required_login
  def show
    @tags = @user.tags.uniq
  end
end
