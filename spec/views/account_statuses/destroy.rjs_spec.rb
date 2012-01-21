require 'spec_helper'

describe "/account_statuses/destroy" do
  fixtures :all
  
  before(:each) do
    render
  end

  subject {  rendered }
  it { should have_prototype_rjs_of :visual_effect, :slide_up, "account_status_body", :duration => '0.2'}
  it { should have_prototype_rjs_of :replace_html, "account_status" }
  it { should have_prototype_rjs_of :delay, 0.2}
end

