require 'spec_helper'

describe "/account_statuses/show.rjs" do
  fixtures :all
  
  before(:each) do
    assigns[:account_statuses] = @account_statuses = { 'income' => [[accounts(:income2), 100]], 'outgo' => [[accounts(:outgo3), 200]], 'account' => [[accounts(:bank1), 300]]}
    render
  end

  subject {  rendered }
  it { should have_prototype_rjs_of :replace_html, "account_status" }
  it { should have_prototype_rjs_of :visual_effect, :slide_down, "account_status_body", :duration => '0.2'}
end

