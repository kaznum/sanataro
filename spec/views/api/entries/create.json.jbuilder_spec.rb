require 'spec_helper'

class ActionView::Base
  def displaying_month
    Date.today
  end
end

describe '/api/entries/create', type: :view do
  fixtures :all

  before(:each) do
    item = Fabricate(:general_item, name: '<a href="bbb">aaa</a>')
    updated_item_ids = [10, 20, 30, 40, 50]

    render template: 'api/entries/create', locals: { item: item, updated_item_ids: updated_item_ids }
  end

  specify { expect( JSON.parse(rendered)['entry']['name'] ).to eq '<a href="bbb">aaa</a>' }
  specify { expect( JSON.parse(rendered)['updated_entry_ids'] ).to eq [10,20,30,40,50] }
end
