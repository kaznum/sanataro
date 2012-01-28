require 'spec_helper'

describe "/common/redirect" do
  before(:each) do
    @path_to_redirect_to = 'http://www.example.com/'
    render
  end
  subject { rendered }
  it { should =~ /location\.href\s*=\s*"#{@path_to_redirect_to}"/ }
end

