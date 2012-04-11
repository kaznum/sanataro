require 'spec_helper'

class ActionView::Base
  def displaying_month
    Date.today
  end
end

describe "/entries/create_item" do
  fixtures :all
  
  before(:each) do
    @item1 = Fabricate(:item, name: "<a href='aaa'>aaa</a>")
    @item1.save!
    @item2 = Fabricate(:item)
    @item2.save!
    @items = [@item1, @item2]
    @updated_item_ids = [10, 20, 30]
    @separated_accounts = {:income_ids => [10, 30, 40],
      :account_ids => [20],
      :all_accounts => {10 => double, 20 => double, 30 => double, 40 => double},
      :account_bgcolors => { 20 => "ffffff"} }
    render template: "entries/create_item", locals: { items: @items, item: @item1, updated_item_ids: @updated_item_ids, :displaying_month => 10 }
  end
  subject { rendered }
  it { should =~ /&lt;a href=\\'aaa\\'&gt;aaa&lt;\/a&gt;/ }
end

