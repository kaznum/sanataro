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
  it { should match /^<div id='year_2008'>2008\|(month_link\|){3}<\/div><div id='year_2009'>2009\|(month_link\|){12}<\/div>/ }
end
