require 'spec_helper'

describe MonthlistHelper do
  before do
    from_year = 2008
    from_month = 10
    to_year = 2009
    to_month = 12
    selected_year = 2009
    selected_month = 8
    current_action = 'foo'

    helper.stub(:link_to_unless).and_return('month_link')
    
    @returned = helper.monthlist(from_year, from_month, to_year, to_month, selected_year, selected_month, current_action)
  end
  
  subject { @returned }
  it { should match /<div id='years'><a href="#year_2008" class="unselected">2008<\/a> \| <a href="#year_2009" class="selected">2009<\/a><\/div>/ }
  it { should match /<div id='year_2008' style='display: none;'>(month_link(\s\|\s)?){3}<\/div><div id='year_2009' style='display: block;'>(month_link(\s\|\s)?){12}<\/div>/ }
end
