# -*- coding: utf-8 -*-

require 'spec_helper'

describe Item, type: :model do
  fixtures :items, :users, :accounts, :monthly_profit_losses
  before do
    @valid_attrs = {
      name: 'aaaa',
      year: 2008,
      month: 10,
      day: 17,
      from_account_id: 1,
      to_account_id: 3,
      amount: 10_000,
      confirmation_required: true,
      tag_list: 'hoge fuga'
    }
  end

  describe 'create successfully' do
    before do
      @item = users(:user1).general_items.create!(@valid_attrs)
      @saved_item = Item.find(@item.id)
    end

    describe "created item's attributes" do
      subject { @saved_item }

      describe '#action_date' do
        subject { super().action_date }
        it { is_expected.to eq(Date.new(2008, 10, 17)) }
      end

      describe '#adjustment?' do
        subject { super().adjustment? }
        it { is_expected.to be_falsey }
      end

      describe '#confirmation_required?' do
        subject { super().confirmation_required? }
        it { is_expected.to be_truthy }
      end
    end
  end

  describe 'validation' do
    before do
      @item = users(:user1).general_items.new(@valid_attrs)
    end

    describe 'name' do
      context 'when name is nil' do
        before do
          @item.name = nil
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:name).size).to be >= 1
          end
        end
      end
    end

    describe 'amount' do
      context 'when amount is nil' do
        before do
          @item.amount = nil
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:amount).size).to be >= 1
          end
        end
      end
    end

    describe 'account_id' do
      context 'when from_account_id is nil,' do
        before do
          @item.from_account_id = nil
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:from_account_id).size).to be >= 1
          end
        end
      end

      context 'when from_account_id is -1,' do
        before do
          @item.from_account_id = -1
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_truthy }
        end

      end

      context 'when from_account_id is not owned by user,' do
        before do
          @item.from_account_id = 21_234
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:from_account_id).size).to be >= 1
          end
        end
      end

      context 'when from_account_id is expense,' do
        before do
          @item.from_account_id = accounts(:expense3).id
          @item.to_account_id = accounts(:expense13).id
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:from_account_id).size).to be >= 1
          end
        end
      end

      context 'when to_account_id is nil,' do
        before do
          @item.to_account_id = nil
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:to_account_id).size).to be >= 1
          end
        end
      end

      context 'when to_account_id is -1,' do
        before do
          @item.to_account_id = -1
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:to_account_id).size).to be >= 1
          end
        end
      end

      context 'when to_account_id is not owned by user,' do
        before do
          @item.from_account_id = -1
          @item.to_account_id = 21_234
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:to_account_id).size).to be >= 1
          end
        end
      end

      context 'when to_account_id is income,' do
        before do
          @item.from_account_id = -1
          @item.to_account_id = accounts(:income2).id
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:to_account_id).size).to be >= 1
          end
        end
      end

      context 'when from_account_id and to_account_id are same,' do
        before do
          @item.from_account_id = 1
          @item.to_account_id = 1
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:from_account_id).size).to be >= 1
          end
        end
      end
    end

    describe 'action_date' do
      context 'when action_date is invalid' do
        before do
          @item.month = 2
          @item.day = 30
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:action_date).size).to be >= 1
          end
        end
      end

      context 'when action_date is too past value' do
        before do
          @item.year = 2005
          @item.month = 2
          @item.day = 10
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:action_date).size).to be >= 1
          end
        end
      end

      context 'when action_date is too future value' do
        before do
          future = 2.years.since(Time.now)
          @item.year = future.year
          @item.month = future.month
          @item.day = future.day
          @is_saved = @item.save
        end

        describe 'item was not saved' do
          subject { @is_saved }
          it { is_expected.to be_falsey }
        end

        describe 'error' do
          subject { @item }
          it 'has at least 1 errors_on' do
            expect(subject.errors_on(:action_date).size).to be >= 1
          end
        end
      end
    end
  end

  describe 'action_date calcuration' do
    before do
      @item = Item.find(1)
    end

    describe 'getting from DB' do
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to eq(2008) }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to eq(2) }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to eq(15) }
      end
    end

    context 'when nil is set to year' do
      before do
        @item.year = nil
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to be_nil }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to be_nil }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to be_nil }
      end

      describe '#action_date' do
        subject { super().action_date }
        it { is_expected.to be_nil }
      end
    end

    context 'when nil is set to month' do
      before do
        @item.month = nil
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to be_nil }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to be_nil }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to be_nil }
      end

      describe '#action_date' do
        subject { super().action_date }
        it { is_expected.to be_nil }
      end
    end

    context 'when nil is set to day' do
      before do
        @item.day = nil
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to be_nil }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to be_nil }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to be_nil }
      end

      describe '#action_date' do
        subject { super().action_date }
        it { is_expected.to be_nil }
      end
    end

    context 'when Date object is set to action_date' do
      before do
        @item.action_date = Date.new(2010, 3, 10)
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to eq(2010) }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to eq(3) }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to eq(10) }
      end

      describe '#action_date' do
        subject { super().action_date }
        it { is_expected.to eq(Date.new(2010, 3, 10)) }
      end
    end
  end

  describe 'adjustment' do
    #
    # 日付の順番は以下のとおり
    # item1 -> adj2 -> item3 -> adj4
    #
    before do
      @item1 = Item.find(1)
      @adj2 = Item.find(2)
      @item3 = Item.find(3)
      @adj4 = Item.find(4)
      @plbank1 = monthly_profit_losses(:bank1200802)
    end

    context 'adjustment2のitemとaction_dateが同一のitemを追加した場合' do
      before do
        item = users(:user1).general_items.create!(name: 'aaaaa',
                                                   action_date: @adj2.action_date,
                                                   from_account_id: 1,
                                                   to_account_id: 3,
                                                   amount: 10_000)
        MonthlyProfitLoss.correct(users(:user1), 1, item.action_date.beginning_of_month)
        MonthlyProfitLoss.correct(users(:user1), 3, item.action_date.beginning_of_month)
        Item.update_future_balance(users(:user1), item.action_date, 1, item.id)
        Item.update_future_balance(users(:user1), item.action_date, 3, item.id)
      end

      describe 'adj2' do
        subject { Item.find(@adj2.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@adj2.amount) }
        end

        describe '#adjustment_amount' do
          subject { super().adjustment_amount }
          it { is_expected.to eq(@adj2.adjustment_amount) }
        end
      end

      describe 'adj4' do
        subject { Item.find(@adj4.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@adj4.amount + 10_000) }
        end

        describe '#adjustment_amount' do
          subject { super().adjustment_amount }
          it { is_expected.to eq(@adj4.adjustment_amount) }
        end
      end

      describe 'monthly profit loss of bank1' do
        subject { MonthlyProfitLoss.find(@plbank1.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@plbank1.amount) }
        end
      end
    end

    context 'item5を変更する(adj6(翌月のadjustment item)に影響がでる。同時にmonthly_profit_lossも翌月に変更が加わる)' do
      before do
        @adj6 = items(:adjustment6)
        @plbank1_03 = monthly_profit_losses(:bank1200803)
        MonthlyProfitLoss.correct(users(:user1), 1, @adj6.action_date.beginning_of_month)
        MonthlyProfitLoss.correct(users(:user1), 3, @adj6.action_date.beginning_of_month)

        item = users(:user1).general_items.create!(id: 105,
                                                   name: 'aaaaa',
                                                   year: @adj6.action_date.year,
                                                   month: @adj6.action_date.month,
                                                   day: @adj6.action_date.day - 1,
                                                   from_account_id: 1,
                                                   to_account_id: 3,
                                                   amount: 200)
        MonthlyProfitLoss.correct(users(:user1), 1, item.action_date.beginning_of_month)
        MonthlyProfitLoss.correct(users(:user1), 3, item.action_date.beginning_of_month)
        Item.update_future_balance(users(:user1), item.action_date, 1, item.id)
        Item.update_future_balance(users(:user1), item.action_date, 3, item.id)
      end

      describe 'adj2' do
        subject { Item.find(2) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@adj2.amount) }
        end

        describe '#adjustment_amount' do
          subject { super().adjustment_amount }
          it { is_expected.to eq(@adj2.adjustment_amount) }
        end
      end

      describe 'adj4' do
        subject { Item.find(4) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@adj4.amount) }
        end

        describe '#adjustment_amount' do
          subject { super().adjustment_amount }
          it { is_expected.to eq(@adj4.adjustment_amount) }
        end
      end

      describe 'adj6' do
        subject { Item.find(@adj6.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@adj6.amount + 200) }
        end

        describe '#adjustment_amount' do
          subject { super().adjustment_amount }
          it { is_expected.to eq(@adj6.adjustment_amount) }
        end
      end

      describe 'MonthlyProfitLoss for bank1 in 2008/2' do
        subject { MonthlyProfitLoss.find(@plbank1.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@plbank1.amount) }
        end
      end

      describe 'MonthlyProfitLoss for bank1 in 2008/3' do
        subject { MonthlyProfitLoss.find(@plbank1_03.id) }

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(@plbank1_03.amount) }
        end
      end
    end
  end

  describe 'partial_items' do
    context 'when entries are so many' do
      before do
        @created_ids = []
        # データの準備
        Item.transaction do
          Item.delete_all

          3.times do |i|
            item = Fabricate.build(:general_item, from_account_id: 11, to_account_id: 13, name: "itemname#{i}", action_date: '2008-09-15', tag_list: 'abc def', confirmation_required: true)
            item.save!
            @created_ids << item.id
          end

          # データの準備
          3.times do |i|
            item = Fabricate.build(:general_item, from_account_id: 21, to_account_id: 13, name: "itemname#{i}", action_date: '2008-09-15', tag_list: 'ghi jkl')
            item.save!
            @created_ids << item.id
          end

          # データの準備(参照されないデータ)
          2.times do |i|
            item = Fabricate.build(:general_item, name: "NOT REFERED #{i}", from_account_id: 11, to_account_id: 13, action_date: '2008-10-01', tag_list: 'mno pqr')
            item.save!
            @created_ids << item.id
          end

          # データの準備(参照されないデータ)(別ユーザ)
          from_account = Fabricate.build(:banking)
          from_account.user_id = 101
          from_account.save!
          to_account = Fabricate.build(:expense)
          to_account.user_id = 101
          to_account.save!

          2.times do |i|
            item = Fabricate.build(:general_item, from_account_id: from_account.id, to_account_id: to_account.id, name: "itemname#{i}", action_date: '2008-09-15', tag_list: 'abc def', confirmation_required: true)
            item.user_id = 101
            item.save!
            @created_ids << item.id
          end
        end

        @from_date = Date.new(2008, 9, 1)
        @to_date = Date.new(2008, 9, 30)
        allow(GlobalSettings).to receive(:item_list_count).and_return(2)
      end

      context 'when :remain is not specified' do
        subject { users(:user1).items.partials(@from_date, @to_date) }
        it 'has GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(GlobalSettings.item_list_count)
        end
      end

      context "when the action_date's order is not same as those of ids" do
        before do
          @item = Fabricate.build(:general_item, from_account_id: 21, to_account_id: 13, name: 'itemname_old', action_date: '2008-09-14', tag_list: 'ghi jkl')
          @item.save!
        end
        subject { users(:user1).items.partials(@from_date, @to_date).first.id }
        it { is_expected.not_to eq(@item.id) }
      end

      context 'when :remain is specified as true' do
        subject { users(:user1).items.partials(@from_date, @to_date, { remain: true }) }
        it 'has 6 - GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(6 - GlobalSettings.item_list_count)
        end
      end

      context 'when :tag is specified' do
        subject { users(:user1).items.partials(nil, nil, { tag: 'abc' }) }
        it 'has GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(GlobalSettings.item_list_count)
        end
      end

      context 'when :tag and :remain is specified' do
        subject { users(:user1).items.partials(nil, nil, { remain: true, tag: 'abc' }) }
        it 'has 3 - GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(3 - GlobalSettings.item_list_count)
        end
      end

      context 'when :keyword is specified' do
        subject { users(:user1).items.partials(nil, nil, { keyword: 'emname' }) }
        it 'has GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(GlobalSettings.item_list_count)
        end
      end

      context 'when :keyword and :remain is specified' do
        subject { users(:user1).items.partials(nil, nil, { remain: true, keyword: 'emname' }) }
        it 'has 6 - GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(6 - GlobalSettings.item_list_count)
        end
      end

      context 'when :filter_account_id is specified' do
        subject { users(:user1).items.partials(@from_date, @to_date, { filter_account_id: accounts(:bank11).id }) }
        it 'has GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(GlobalSettings.item_list_count)
        end
      end

      context 'when :filter_account_id and :remain is specified' do
        subject { users(:user1).items.partials(@from_date, @to_date, { filter_account_id: accounts(:bank11).id, remain: true }) }
        it 'has 3 - GlobalSettings.item_list_count entries' do
          expect(subject.entries.size).to eq(3 - GlobalSettings.item_list_count)
        end
      end

      context 'when confirmation required is specified' do
        context 'when remain not specified' do
          subject { users(:user1).items.partials(nil, nil, { mark: 'confirmation_required' }) }
          it 'has GlobalSettings.item_list_count entries' do
            expect(subject.entries.size).to eq(GlobalSettings.item_list_count)
          end
        end

        context 'when remain not specified' do
          before do
            @cnfmt_rqrd_count = Item.where(confirmation_required: true, user_id: users(:user1).id).count
          end

          subject { users(:user1).items.partials(nil, nil, { mark: 'confirmation_required', remain: true }) }
          it 'has @cnfmt_rqrd_count - GlobalSettings.item_list_count entries' do
            expect(subject.entries.size).to eq(@cnfmt_rqrd_count - GlobalSettings.item_list_count)
          end
        end
      end
    end

    context 'when entries are not so many' do
      before do
        @created_ids = []
        # データの準備
        Item.transaction do
          3.times do |i|
            item = GeneralItem.new(name: 'regular item ' + i.to_s,
                                   from_account_id: 11,
                                   to_account_id: 13,
                                   action_date: Date.new(2008, 9, 15),
                                   tag_list: 'abc def',
                                   confirmation_required: true,
                                   amount: 100 + i)
            item.user_id = 1
            item.save!
            @created_ids << item.id
          end

          # データの準備
          1.times do |i|
            item = GeneralItem.new(name: 'regular item ' + i.to_s,
                                   from_account_id: 21,
                                   to_account_id: 13,
                                   action_date: Date.new(2008, 9, 15),
                                   tag_list: 'ghi jkl',
                                   amount: 100 + i)
            item.user_id = 1
            item.save!
            @created_ids << item.id
          end

          # データの準備(参照されないデータ)
          2.times do |i|
            item = GeneralItem.new(name: 'regular item ' + i.to_s,
                                   from_account_id: 11,
                                   to_account_id: 13,
                                   action_date: Date.new(2008, 10, 1), # 参照されない日付
                                   tag_list: 'mno pqr',
                                   amount: 100 + i)
            item.user_id = 1
            item.save!
            @created_ids << item.id
          end

          # データの準備(参照されないデータ)(別ユーザ)
          from_account = Fabricate.build(:banking)
          from_account.user_id = 101
          from_account.save!
          to_account = Fabricate.build(:expense)
          to_account.user_id = 101
          to_account.save!
          2.times do |i|
            item = GeneralItem.new(name: 'regular item ' + i.to_s,
                                   from_account_id: from_account.id,
                                   to_account_id: to_account.id,
                                   action_date: Date.new(2008, 9, 15),
                                   amount: 100 + i)
            item.user_id = 101
            item.save!
            @created_ids << item.id
          end

        end
        @from_date = Date.new(2008, 9, 1)
        @to_date = Date.new(2008, 9, 30)
        allow(GlobalSettings).to receive(:item_list_count).and_return(5)
      end

      after do
        Item.transaction do
          Item.delete_all
        end
      end

      context 'when :remain is not specified' do
        subject { users(:user1).items.partials(@from_date, @to_date) }
        it 'has 4 entries' do
          expect(subject.entries.size).to eq(4)
        end
      end

      context 'when :remain is true' do
        subject { users(:user1).items.partials(@from_date, @to_date, { 'remain' => true }) }
        it 'has no entries' do
          expect(subject.entries.size).to eq(0)
        end
      end

      context 'when :filter_account_id is specified' do
        subject { users(:user1).items.partials(@from_date, @to_date, { filter_account_id: accounts(:bank11).id }) }
        it 'has 3 entries' do
          expect(subject.entries.size).to eq(3)
        end
      end

      context 'when :filter_account_id and :remain is specified' do
        subject { users(:user1).items.partials(@from_date, @to_date, { filter_account_id: accounts(:bank11).id, remain: true }) }
        it 'has no entries' do
          expect(subject.entries.size).to eq(0)
        end
      end
    end
  end

  describe 'collect_account_history' do
    describe 'amount' do
      before do
        @amount, @items = Item.collect_account_history(users(:user1), accounts(:bank1).id, Date.new(2008, 2, 1), Date.new(2008, 2, 29))
      end

      describe 'amount' do
        subject { @amount }
        it { is_expected.to eq(8000) }
      end

      describe 'items' do
        subject { @items }
        specify {
          subject.each do |item|
            expect(item.from_account_id == accounts(:bank1).id || item.to_account_id == accounts(:bank1).id).to be_truthy
            expect(item.action_date).to be_between Date.new(2008, 2, 1), Date.new(2008, 2, 29)
          end
        }
      end
    end
  end

  describe 'user' do
    subject { Item.find(items(:item1).id) }

    describe '#user' do
      subject { super().user }
      it { is_expected.not_to be_nil }
    end
    specify { expect(subject.user.id).to eq(subject.user_id) }
  end

  describe 'child_item' do
    before do
      p_it = users(:user1).general_items.new(name: 'p hogehoge',
                                             from_account_id: 1,
                                             to_account_id: 3,
                                             amount: 500,
                                             action_date: Date.new(2008, 2, 10))
      c_it = users(:user1).general_items.new(name: 'c hogehoge',
                                             from_account_id: 11,
                                             to_account_id: 1,
                                             amount: 500,
                                             parent_id: p_it.id,
                                             action_date: Date.new(2008, 3, 10))

      p_it.child_item = c_it
      p_it.save!

      @p_id = p_it.id
      @c_id = c_it.id
    end

    describe 'parent_item' do
      subject { Item.find(@p_id) }
      it { is_expected.not_to be_nil }
    end

    describe 'child_item' do
      subject { Item.find(@c_id) }
      it { is_expected.not_to be_nil }
    end

    describe 'child_item from parent_item' do
      subject { Item.find(@p_id).child_item }
      it { is_expected.not_to be_nil }

      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(@c_id) }
      end
    end

    context "when child_item's action_date is changed," do
      before do
        @child_item = Item.find(@c_id)
        @action = -> { @child_item.update_attributes!(action_date: Date.new(2008, 3, 20)) }
      end

      it { expect { @action.call }.not_to change { Item.find(@p_id).action_date } }
      it { expect { @action.call }.to change { Item.find(@p_id).child_item.action_date }.to(Date.new(2008, 3, 20)) }
    end

    context "when child_item's action_date try to be changed but action_date is before that of parent_item," do
      before do
        @child_item = Item.find(@c_id)
        @action = -> { @child_item.update_attributes!(action_date: Date.new(2008, 2, 9)) }
      end
      it { expect { @action.call }.to raise_error ActiveRecord::RecordInvalid }
    end
  end

  describe 'confirmation_required' do
    context 'parent_idのないitemでupdate_confirmation_requiredを呼びだすとき' do
      before do
        @item = items(:item1)
        @item.update_confirmation_required_of_self_or_parent(false)
      end

      subject { Item.find(@item.id) }
      it { is_expected.not_to be_confirmation_required }
    end

    context 'parent_idが存在するitemでupdate_confirmation_requiredを呼びだすとき' do
      before do
        @child_item = items(:credit_refill31)
        @child_item.update_confirmation_required_of_self_or_parent(true)
      end

      describe 'child_item(self)' do
        subject { Item.find(@child_item.id) }
        it { is_expected.not_to be_confirmation_required }
      end

      describe 'parent_item' do
        subject { Item.find(@child_item.parent_id) }
        it { is_expected.to be_confirmation_required }
      end
    end
  end

  describe '#to_custom_hash' do
    before do
      @valid_attrs = {
        name: 'aaaa',
        year: 2008,
        month: 10,
        day: 17,
        from_account_id: 4,
        to_account_id: 3,
        amount: 10_000,
        confirmation_required: true,
        tag_list: 'hoge fuga',
      }

      @item = users(:user1).general_items.create!(@valid_attrs)
      # acts_as_taggable plugin has a bug. After creating, #tags returns empty array.
      @item.reload
    end

    describe 'item.to_custom_hash' do
      subject { @item.to_custom_hash }
      it { is_expected.to be_an_instance_of(Hash) }

      describe '[:entry]' do
        subject { super()[:entry] }
        it { is_expected.to be_an_instance_of(Hash) }
      end
    end

    describe 'item.to_custom_hash[:entry]' do
      fixtures :credit_relations
      subject { @item.to_custom_hash[:entry] }

      describe '[:id]' do
        subject { super()[:id] }
        it { is_expected.to eq(@item.id) }
      end

      describe '[:name]' do
        subject { super()[:name] }
        it { is_expected.to eq('aaaa') }
      end

      describe '[:action_date]' do
        subject { super()[:action_date] }
        it { is_expected.to eq(Date.new(2008, 10, 17)) }
      end

      describe '[:from_account_id]' do
        subject { super()[:from_account_id] }
        it { is_expected.to eq(4) }
      end

      describe '[:to_account_id]' do
        subject { super()[:to_account_id] }
        it { is_expected.to eq(3) }
      end

      describe '[:amount]' do
        subject { super()[:amount] }
        it { is_expected.to eq(10_000) }
      end

      describe '[:confirmation_required]' do
        subject { super()[:confirmation_required] }
        it { is_expected.to be_truthy }
      end

      describe '[:tags]' do
        subject { super()[:tags] }
        it { is_expected.to eq(%w(fuga hoge)) }
      end

      describe '[:child_id]' do
        subject { super()[:child_id] }
        it { is_expected.not_to be_nil }
      end

      describe '[:child_id]' do
        subject { super()[:child_id] }
        it { is_expected.to eq(@item.child_item.id) }
      end
    end

    describe 'child_item.to_custom_hash[:entry]' do
      fixtures :credit_relations
      subject { @item.child_item.to_custom_hash[:entry] }

      describe '[:id]' do
        subject { super()[:id] }
        it { is_expected.to eq(@item.child_item.id) }
      end

      describe '[:name]' do
        subject { super()[:name] }
        it { is_expected.to eq('aaaa') }
      end

      describe '[:action_date]' do
        subject { super()[:action_date] }
        it { is_expected.to eq(Date.new(2008, 12, 20)) }
      end

      describe '[:from_account_id]' do
        subject { super()[:from_account_id] }
        it { is_expected.to eq(1) }
      end

      describe '[:to_account_id]' do
        subject { super()[:to_account_id] }
        it { is_expected.to eq(4) }
      end

      describe '[:amount]' do
        subject { super()[:amount] }
        it { is_expected.to eq(10_000) }
      end

      describe '[:confirmation_required]' do
        subject { super()[:confirmation_required] }
        it { is_expected.to be_falsey }
      end

      describe '[:tags]' do
        subject { super()[:tags] }
        it { is_expected.to be_blank }
      end

      describe '[:child_id]' do
        subject { super()[:child_id] }
        it { is_expected.to be_nil }
      end

      describe '[:parent_id]' do
        subject { super()[:parent_id] }
        it { is_expected.to eq(@item.id) }
      end
    end
  end

  describe 'items.to_custom_hash' do
    describe 'Array#to_custom_hash' do
      before do
        @items = Item.where(user_id: users(:user1).id).to_a
      end
      subject { @items.to_custom_hash }
      it { is_expected.to be_an_instance_of(Array) }

      describe '[0]' do
        subject { super()[0] }
        it { is_expected.to eq(@items[0].to_custom_hash) }
      end
    end
  end

  describe '#year, #month, #day' do
    context 'when p_year, p_month, p_day is set,' do
      before do
        @item = Item.new
        @item.p_year = 2000
        @item.p_month = 1
        @item.p_day = 3
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to eq(2000) }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to eq(1) }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to eq(3) }
      end
    end

    context 'when action_date is set,' do
      before do
        @item = Item.new
        @item.action_date = Date.today
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to eq(Date.today.year) }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to eq(Date.today.month) }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to eq(Date.today.day) }
      end
    end

    context 'when neither action_date nor p_* are set,' do
      before do
        @item = Item.new
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to be_nil }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to be_nil }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to be_nil }
      end
    end

    context 'when both action_date and p_* are set,' do
      before do
        @item = Item.new
        @item.action_date = Date.today
        @item.year = 2000
        @item.month = 10
        @item.day = 20
      end
      subject { @item }

      describe '#year' do
        subject { super().year }
        it { is_expected.to eq(2000) }
      end

      describe '#month' do
        subject { super().month }
        it { is_expected.to eq(10) }
      end

      describe '#day' do
        subject { super().day }
        it { is_expected.to eq(20) }
      end
    end
  end

  describe '#calc_amount' do
    context 'when amount is 1/20*400,' do
      subject { Item.calc_amount('1/20*400') }
      it { is_expected.to eq(20) }
    end

    context 'when amount is 10 * 20,' do
      subject { Item.calc_amount('10 * 20') }
      it { is_expected.to eq(200) }
    end

    context 'when amount is 10 + 20.5,' do
      subject { Item.calc_amount('10 + 20.5') }
      it { is_expected.to eq(30) }
    end

    context "when amount is '200'.to_i ," do
      it { expect { Item.calc_amount("'200'.to_i") }.to raise_error(SyntaxError) }
    end
  end
end
