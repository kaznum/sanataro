require 'spec_helper'

describe "/account_statuses/destroy" do
  fixtures :all
  
  before(:each) do
    render
  end

  subject {  rendered }
  it { should =~ /\$\("#account_status_body"\)\.slideUp\(200\);/}
  it { should =~ /\$\("#account_status"\).html\(/ }
  it { should have_prototype_rjs_of :delay, 0.2}
end

