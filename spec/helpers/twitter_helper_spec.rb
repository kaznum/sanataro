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
  it { should match /#{URI.escape(@item.name)}/ }
  it { should match /#{URI.escape("1,500円")}/ }
  it { should match /hashtags=aaa,bbb,sanataro/ }
  it { should match /onclick="open_twitter\(this.getAttribute\('href'\)\);return false;/ }
end

