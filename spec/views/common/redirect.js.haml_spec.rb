require 'spec_helper'

describe '/common/redirect', type: :view do
  before(:each) do
    @path_to_redirect_to = 'http://www.example.com/'
    render
  end
  subject { rendered }
  it { is_expected.to match(/location\.href\s*=\s*"#{@path_to_redirect_to}"/) }
end
