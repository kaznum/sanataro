require 'spec_helper'

class ActionView::Base
  def displaying_month
    Date.today
  end
end

describe '/entries/create_item', :type => :view do
  fixtures :all

  before(:each) do
    mock_user = users(:user1)
    expect(mock_user).to receive(:all_accounts).at_least(:once).and_return({ 10 => double, 20 => double, 30 => double, 40 => double })
    expect(mock_user).to receive(:account_bgcolors).at_least(:once).and_return({ 20 => 'ffffff' })
    assign(:user, mock_user)

    @item1 = Fabricate(:general_item, name: "<a href='aaa'>aaa</a>")
    @item1.save!
    @item2 = Fabricate(:general_item)
    @item2.save!
    @items = [@item1, @item2]
    @updated_item_ids = [10, 20, 30]
    render template: 'entries/create_item', locals: { items: @items, item: @item1, updated_item_ids: @updated_item_ids, displaying_month: 10 }
  end
  subject { rendered }
  it { is_expected.to match(/&lt;a href=&#39;aaa&#39;&gt;aaa&lt;\/a&gt;/) }
end
