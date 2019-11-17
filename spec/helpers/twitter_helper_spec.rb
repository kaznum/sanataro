# -*- coding: utf-8 -*-
require 'spec_helper'

describe TwitterHelper, type: :helper do
  fixtures :users, :accounts
  context 'when to_account_id is outgoing,' do
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: 1, to_account_id: 3, tag_list: 'aaa bbb')
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { is_expected.to match /#{CGI.escape(@item.name)}/ }
    it { is_expected.to match /#{CGI.escape("[" + Account.find(3).name + "]")}/ }
    it { is_expected.to match /#{CGI.escape("1,500円")}/ }
    it { is_expected.to match /hashtags=#{CGI.escape('aaa,bbb,sanataro')}/ }
    it { is_expected.to match /onclick="open_twitter\(this.getAttribute\(&#39;href&#39;\)\);return false;/ }
  end

  context 'when from_account_id is income,' do
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: 2, to_account_id: 1, tag_list: 'aaa bbb')
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { is_expected.to match /#{CGI.escape(@item.name)}/ }
    it { is_expected.to match /#{CGI.escape("[" + Account.find(2).name + "]")}/ }
    it { is_expected.to match /#{CGI.escape("1,500円")}/ }
    it { is_expected.to match /hashtags=#{CGI.escape('aaa,bbb,sanataro')}/ }
    it { is_expected.to match /onclick="open_twitter\(this.getAttribute\(&#39;href&#39;\)\);return false;/ }
  end

  context 'when both from_account_id and to_account_id are bank accounts,' do
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: 11, to_account_id: 1, tag_list: 'aaa bbb')
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { is_expected.to match /#{CGI.escape(@item.name)}/ }
    it { is_expected.not_to match /#{CGI.escape(Account.find(11).name)}/ }
    it { is_expected.not_to match /#{CGI.escape(Account.find(1).name)}/ }
    it { is_expected.to match /#{CGI.escape("1,500円")}/ }
    it { is_expected.to match /hashtags=#{CGI.escape('aaa,bbb,sanataro')}/ }
    it { is_expected.to match /onclick="open_twitter\(this.getAttribute\(&#39;href&#39;\)\);return false;/ }
  end

  context 'when item is adjustment,' do
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: -1, to_account_id: 1, tag_list: 'aaa bbb')
      @item.save!
      @item.reload
    end

    subject { helper.tweet_button(@item) }
    it { is_expected.to match /#{CGI.escape(@item.name)}/ }
    it { is_expected.not_to match /#{CGI.escape(Account.find(1).name)}/ }
    it { is_expected.to match /#{CGI.escape("1,500円")}/ }
    it { is_expected.to match /hashtags=#{CGI.escape('aaa,bbb,sanataro')}/ }
    it { is_expected.to match /onclick="open_twitter\(this.getAttribute\(&#39;href&#39;\)\);return false;/ }
  end
end
