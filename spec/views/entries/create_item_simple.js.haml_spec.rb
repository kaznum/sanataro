require 'spec_helper'

describe "/entries/create_item_simple" do
  fixtures :all
  
  before(:each) do
    @item1 = Fabricate(:item, name: "<a href='aaa'>aaa</a>")
    @item1.save!
    render template: "entries/create_item_simple", locals: { item: @item1 }
  end
  subject { rendered }
  it { should =~ /&lt;a href=&#x27;aaa&#x27;&gt;aaa&lt;\/a&gt;/ }
end

