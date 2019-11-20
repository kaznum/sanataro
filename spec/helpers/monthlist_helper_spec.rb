# frozen_string_literal: true

require 'spec_helper'

describe MonthlistHelper, type: :helper do
  before do
    from_year = 2008
    from_month = 10
    to_year = 2009
    to_month = 12
    selected_year = 2009
    selected_month = 8
    current_action = 'foo'

    allow(helper).to receive(:link_to).and_return('month_link')
    expect(helper).to receive(:link_to).with(2008, '#year_2008', class: 'unselected').and_return('year_2008_link')
    expect(helper).to receive(:link_to).with(2009, '#year_2009', class: 'selected').and_return('year_2009_link')

    @returned = helper.monthlist(from_year, from_month, to_year, to_month, selected_year, selected_month, current_action)
  end

  subject { @returned }
  it { is_expected.to match(/<div class='years'>year_2008_linkyear_2009_link<\/div>/) }
  it { is_expected.to match(%r(<div class='year_2008' style='display: none;'>(month_link){3}</div><div class='year_2009' style='display: block;'>(month_link){12}</div>)) }
end
