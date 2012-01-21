require 'spec_helper'

describe "/common/redirect" do
  before(:each) do
    @path_to_redirect_to = 'http://www.example.com/'
    render
  end
  subject {  rendered }
  it { should have_prototype_rjs_of(:redirect_to, @path_to_redirect_to) }
end

