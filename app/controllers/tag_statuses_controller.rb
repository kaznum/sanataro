class TagStatusesController < ApplicationController
  before_action :required_login
  def show
    @tags = @user.tags.order(:name).uniq.sort {|a,b| a.name <=> b.name }
  end
end
