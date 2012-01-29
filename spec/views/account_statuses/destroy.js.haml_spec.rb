require 'spec_helper'

describe "/account_statuses/destroy" do
  fixtures :all
  
  before(:each) do
    render
  end

  subject {  rendered }
  it { should =~ /\$\("#account_status_body"\)\.slideUp\(200, function\(\) {/}
  it { should =~ /\$\("#account_status"\).html\(/ }
end

