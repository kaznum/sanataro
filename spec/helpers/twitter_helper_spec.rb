# -*- coding: utf-8 -*-
require 'spec_helper'

describe TwitterHelper do
  fixtures :users
  before do
    @item = Fabricate.build(:item, amount: 1500, tag_list: "aaa bbb")
    @item.save!
    @item.reload
  end

  subject { helper.tweet_button(@item) }
  it { should match /data-text="#{@item.name} \(1,500円\)"/ }
  it { should match /data-hashtags="aaa,bbb,sanataro"/ }
  it { should match /<script>/ }
end
