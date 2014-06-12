require 'spec_helper'

describe "/entries/create_item_simple", :type => :view do
  fixtures :all

  before(:each) do
    @item1 = Fabricate(:general_item, name: "<a href='aaa'>aaa</a>")
    @item1.save!
    render template: "entries/create_item_simple", locals: { item: @item1 }
  end
  subject { rendered }
  it { is_expected.to match(/&lt;a href=&#39;aaa&#39;&gt;aaa&lt;\/a&gt;/) }
end
