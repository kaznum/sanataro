# -*- coding: utf-8 -*-
require 'spec_helper'

describe TwitterHelper do
  fixtures :users, :accounts
  context "when to_account_id is outgoing," do
    before do
      @item = Fabricate.build(:item, amount: 1500, from_account_id: 1, to_account_id: 3, tag_list: "aaa bbb")
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { should match /#{URI.escape(@item.name)}/ }
    it { should match /#{URI.escape("[" + Account.find(3).name + "]")}/ }
    it { should match /#{URI.escape("1,500円")}/ }
    it { should match /hashtags=aaa,bbb,sanataro/ }
    it { should match /onclick="open_twitter\(this.getAttribute\('href'\)\);return false;/ }
  end
  
  context "when from_account_id is income," do
    before do
      @item = Fabricate.build(:item, amount: 1500, from_account_id: 2, to_account_id: 1, tag_list: "aaa bbb")
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { should match /#{URI.escape(@item.name)}/ }
    it { should match /#{URI.escape("[" + Account.find(2).name + "]")}/ }
    it { should match /#{URI.escape("1,500円")}/ }
    it { should match /hashtags=aaa,bbb,sanataro/ }
    it { should match /onclick="open_twitter\(this.getAttribute\('href'\)\);return false;/ }
  end

  context "when both from_account_id and to_account_id are bank accounts," do
    before do
      @item = Fabricate.build(:item, amount: 1500, from_account_id: 11, to_account_id: 1, tag_list: "aaa bbb")
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { should match /#{URI.escape(@item.name)}/ }
    it { should_not match /#{URI.escape(Account.find(11).name)}/ }
    it { should_not match /#{URI.escape(Account.find(1).name)}/ }
    it { should match /#{URI.escape("1,500円")}/ }
    it { should match /hashtags=aaa,bbb,sanataro/ }
    it { should match /onclick="open_twitter\(this.getAttribute\('href'\)\);return false;/ }
  end
  
  context "when item is adjustment," do
    before do
      @item = Fabricate.build(:item, amount: 1500, from_account_id: -1, to_account_id: 1, tag_list: "aaa bbb")
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { should match /#{URI.escape(@item.name)}/ }
    it { should_not match /#{URI.escape(Account.find(1).name)}/ }
    it { should match /#{URI.escape("1,500円")}/ }
    it { should match /hashtags=aaa,bbb,sanataro/ }
    it { should match /onclick="open_twitter\(this.getAttribute\('href'\)\);return false;/ }
  end
end

