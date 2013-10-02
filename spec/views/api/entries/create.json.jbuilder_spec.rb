require 'spec_helper'

class ActionView::Base
  def displaying_month
    Date.today
  end
end

describe "/api/entries/create" do
  fixtures :all

  before(:each) do
    item = Fabricate(:general_item, name: '<a href="bbb">aaa</a>')
    updated_item_ids = [10, 20, 30, 40, 50]

    render template: "api/entries/create", locals: { item: item, updated_item_ids: updated_item_ids }
  end

  subject { rendered }
  it { should be =~ /{"entry":{.*"name":"\\u003Ca href=\\"bbb\\"\\u003Eaaa\\u003C\/a\\u003E"/ }
  it { should be =~ /"updated_entry_ids":\[10,20,30,40,50\]}/ }
end

