# frozen_string_literal: true

require 'spec_helper'

describe EntriesController, type: :controller do
  fixtures :all

  describe '#index' do
    context 'before login,' do
      before do
        get :index
      end

      it_should_behave_like 'Unauthenticated Access'
    end

    context 'after login,' do
      let(:mock_user) { users(:user1) }
      before do
        mock_user
        expect(User).to receive(:find).with(mock_user.id).at_least(1).and_return(mock_user)
        dummy_login
      end

      context 'when input values are invalid,' do
        before do
          get :index, year: '2008', month: '13'
        end

        subject { response }
        it { is_expected.to redirect_to current_entries_url }
      end

      shared_examples_for 'Success' do
        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index' }
        end
      end

      shared_examples_for 'no params' do
        it_should_behave_like 'Success'

        describe '@new_item' do
          subject { assigns(:new_item) }

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq Date.today }
          end
        end

        describe '@items' do
          subject { assigns(:items) }
          specify do
            subject.each do |item|
              expect(item.action_date).to be_between(Date.today.beginning_of_month, Date.today.end_of_month)
            end
          end
        end
      end

      context 'when year and month are not specified,' do
        before do
          get :index
        end
        it_should_behave_like 'no params'
      end

      context 'when year and month are specified,' do
        context "when year and month is today's ones," do
          before do
            get :index, year: Date.today.year, month: Date.today.month
          end
          it_should_behave_like 'no params'
        end

        context "when year and month is specified but they are not today's ones," do
          before do
            get :index, year: '2008', month: '2'
          end

          it_should_behave_like 'Success'

          describe '@new_item' do
            subject { assigns(:new_item) }

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.new(2008, 2) }
            end
          end

          describe '@items' do
            subject { assigns(:items) }
            specify do
              subject.each do |item|
                expect(item.action_date).to be_between(Date.new(2008, 2), Date.new(2008, 2).end_of_month)
              end
            end
          end
        end
      end

      context 'with tag,' do
        before do
          tags = %w(test_tag def)
          Teller.update_entry(users(:user1), items(:item11).id, tag_list: tags.join(' '))
          get :index, tag: 'test_tag'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index_with_tag_keyword' }
        end

        describe '@items' do
          subject { assigns(:items) }
          it 'has 1 item' do
            expect(subject.size).to eq(1)
          end
        end

        describe '@tag' do
          subject { assigns(:tag) }
          it { is_expected.to eq 'test_tag' }
        end
      end

      context 'with mark,' do
        before do
          Teller.update_entry(users(:user1), items(:item11).id, confirmation_required: true)
          get :index, mark: 'confirmation_required'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index_with_mark' }
        end

        describe '@items' do
          subject { assigns(:items) }
          it 'has Item.where(confirmation_required: true).count items' do
            expect(subject.size).to eq(Item.where(confirmation_required: true).count)
          end
          specify do
            subject.each do |item|
              expect(item).to be_confirmation_required
            end
          end
        end
      end

      context 'with keyword,' do
        before do
          Teller.update_entry(users(:user1), items(:item11).id, name: 'あああテスト11いいい')
          get :index, keyword: 'テスト11'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index_with_tag_keyword' }
        end

        describe '@items' do
          subject { assigns(:items) }

          describe '#size' do
            subject { super().size }
            it { is_expected.to eq 1 }
          end
        end
      end

      context 'with multiple keywords,' do
        before do
          Teller.update_entry(users(:user1), items(:item11).id, name: 'あああテスト11いいい')
          get :index, keyword: 'テスト  い'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index_with_tag_keyword' }
        end

        describe '@items' do
          subject { assigns(:items) }

          describe '#size' do
            subject { super().size }
            it { is_expected.to eq 1 }
          end
        end
      end

      context 'with keyword which has % ,' do
        before do
          Teller.update_entry(users(:user1), items(:item11).id, name: 'あああテスト11%いいい')
          get :index, keyword: 'テスト11%い'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'index_with_tag_keyword' }
        end

        describe '@items' do
          subject { assigns(:items) }

          describe '#size' do
            subject { super().size }
            it { is_expected.to eq 1 }
          end
        end
      end

      context 'with filter change,' do
        context 'with valid filter_account_id,' do
          shared_examples_for 'filtered index' do
            describe 'response' do
              subject { response }
              it { is_expected.to be_success }
            end

            describe '@items' do
              subject { assigns(:items) }
              specify do
                subject.each do |item|
                  expect([item.from_account_id, item.to_account_id]).to include(accounts(:bank1).id)
                end
              end
            end

            describe 'session[:filter_account_id]' do
              subject {  session[:filter_account_id] }
              it { is_expected.to eq accounts(:bank1).id }
            end
          end

          before do
            xhr :get, :index, filter_account_id: accounts(:bank1).id, year: '2008', month: '2'
          end

          it_should_behave_like 'filtered index'

          describe 'response' do
            subject { response }
            it { is_expected.to render_template 'index_with_filter_account_id' }
          end

          context 'after changing filter, access index with no filter_account_id,' do
            before do
              xhr :get, :index, year: '2008', month: '2'
            end

            describe 'response' do
              subject { response }
              it { is_expected.to render_template 'index' }
            end
            it_should_behave_like 'filtered index'
          end

          context "after changing filter, access with filter_account_id = ''," do
            before do
              @non_bank1_item = users(:user1).general_items.create!(name: 'not bank1 entry', action_date: Date.new(2008, 2, 15), from_account_id: accounts(:income2).id, to_account_id: accounts(:expense3).id, amount: 1000)
              expect(session[:filter_account_id]).to eq accounts(:bank1).id
              xhr :get, :index, filter_account_id: '', year: '2008', month: '2'
            end

            describe 'session[:filter_account_id]' do
              subject { session[:filter_account_id] }
              it { is_expected.to be_nil }
            end

            describe '@items' do
              subject { assigns(:items) }
              it { is_expected.to include(@non_bank1_item) }
            end

            describe 'response' do
              subject { response }
              it { is_expected.to render_template 'index_with_filter_account_id' }
            end
          end
        end
      end

      context 'with params[:remaining] = true,' do
        shared_examples_for 'executed correctly' do
          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_template 'index_for_remaining' }
          end
        end

        context 'without other params,' do
          describe 'user.items.partials' do
            it 'is called with :remain => true' do
              stub_date_from = Date.new(2008, 2)
              stub_date_to = Date.new(2008, 2).end_of_month
              mock_items = users(:user1).items
              expect(mock_user).to receive(:items).and_return(mock_items)
              expect(mock_items).to receive(:partials).with(stub_date_from, stub_date_to,
                                                            hash_including(remain: true)).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).load)
              xhr :get, :index, remaining: 1, year: 2008, month: 2
            end
          end

          describe 'other than user.items.partials' do
            before do
              mock_items = users(:user1).items
              expect(mock_user).to receive(:items).and_return(mock_items)
              allow(mock_items).to receive(:partials).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).load)
              xhr :get, :index, remaining: true, year: 2008, month: 2
            end

            it_should_behave_like 'executed correctly'

            describe '@items' do
              subject { assigns(:items) }
              it { is_expected.not_to be_empty }
            end
          end
        end

        context "and params[:tag] = 'xxx'," do
          describe 'user.items.partials' do
            it "called with tag => 'xxx' and :remain => true" do
              mock_items = users(:user1).items
              expect(mock_user).to receive(:items).and_return(mock_items)
              expect(mock_items).to receive(:partials).with(nil, nil,
                                                            hash_including(tag: 'xxx', remain: true)).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).load)
              xhr :get, :index, remaining: true, year: 2008, month: 2, tag: 'xxx'
            end
          end

          describe 'other than user.items.partials,' do
            before do
              allow(Item).to receive(:partials).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).load)
              xhr :get, :index, remaining: true, year: 2008, month: 2, tag: 'xxx'
            end

            it_should_behave_like 'executed correctly'

            describe '@items' do
              subject { assigns(:items) }
              # 0 item for  remaining
              it { is_expected.not_to be_empty }
            end
          end
        end

        context 'and invalid year and month in params,' do
          before do
            xhr :get, :index, remaining: true, year: 2008, month: 15
          end
          describe 'response' do
            subject { response }
            it { is_expected.to redirect_by_js_to current_entries_url }
          end
        end
      end
    end
  end

  describe '#edit' do
    context 'before login,' do
      before do
        xhr :get, :edit, id: items(:item1).id.to_s
      end
      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before { dummy_login }

      %i[item1 adjustment2 credit_refill31].each do |item_name|
        shared_examples_for "execute edit successfully of #{item_name}" do
          describe 'resposne' do
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_template 'edit' }
          end

          describe '@item' do
            subject { assigns(:item) }

            describe '#id' do
              subject { super().id }
              it { is_expected.to eq items(item_name).id }
            end
          end
        end
      end

      context 'with entry_id,' do
        before do
          xhr :get, :edit, id: items(:item1).id
        end
        it_should_behave_like 'execute edit successfully of item1'
      end

      context 'with adjustment_id,' do
        before do
          xhr :get, :edit, id: items(:adjustment2).id
        end
        it_should_behave_like 'execute edit successfully of adjustment2'
      end

      context 'with child_id,' do
        before do
          xhr :get, :edit, id: items(:credit_refill31).id
        end
        it_should_behave_like 'execute edit successfully of credit_refill31'
      end
    end
  end

  describe '#show' do
    context 'before login,' do
      before do
        xhr :get, :show, id: items(:item1).id
      end
      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before { dummy_login }

      context 'with valid id,' do
        before do
          xhr :get, :show, id: items(:item1).id
        end

        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'show' }
      end
    end
  end

  describe '#new' do
    context 'before login,' do
      before do
        xhr :get, :new
      end

      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login,' do
      before { dummy_login }

      context 'without any params,' do
        before do
          xhr :get, :new
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'new' }
        end

        describe '@item' do
          subject { assigns(:item) }

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq Date.today }
          end
          it { is_expected.not_to be_adjustment }
        end
      end

      context 'with year and month in params,' do
        before do
          xhr :get, :new, year: '2008', month: '5'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'new' }
        end

        describe '@item' do
          subject { assigns(:item) }

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq Date.new(2008, 5) }
          end
          it { is_expected.not_to be_adjustment }
        end
      end

      context 'with entry_type = adjustment in params,' do
        shared_examples_for 'respond successfully' do
          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_template 'new' }
          end
        end

        context 'and no year and month in params,' do
          before do
            xhr :get, :new, entry_type: 'adjustment'
          end

          it_should_behave_like 'respond successfully'

          describe 'item' do
            subject { assigns(:item) }

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.today }
            end
            it { is_expected.to be_adjustment }
          end
        end

        context 'and year and month in params,' do
          context 'and correct date is specified,' do
            before do
              xhr :get, :new, entry_type: 'adjustment', year: '2009', month: '5'
            end

            it_should_behave_like 'respond successfully'

            describe '@item' do
              subject { assigns(:item) }

              describe '#action_date' do
                subject { super().action_date }
                it { is_expected.to eq Date.new(2009, 5) }
              end
              it { is_expected.to be_adjustment }
            end
          end

          context 'and invalid date is specified,' do
            before do
              xhr :get, :new, entry_type: 'adjustment', year: '2009', month: '15'
            end

            it_should_behave_like 'respond successfully'

            describe 'item.action_date' do
              subject { assigns(:item) }

              describe '#action_date' do
                subject { super().action_date }
                it { is_expected.to eq Date.today }
              end
              it { is_expected.to be_adjustment }
            end
          end
        end
      end

      context 'with entry_type = simple in params,' do
        let(:mock_user) { users(:user1) }
        before do
          mock_user
          expect(User).to receive(:find).with(mock_user.id).and_return(mock_user)
          expect(mock_user).to receive(:from_accounts).at_least(:once).and_return([%w(a b), %w(c d)])
          expect(mock_user).to receive(:to_accounts).at_least(:once).and_return([%w(e f), %w(g h)])

          expect(@controller).to receive(:form_authenticity_token).and_return('1234567')
          xhr :get, :new, entry_type: 'simple'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template 'new_simple' }
        end

        describe '@data' do
          subject { assigns(:data) }

          describe '[:authenticity_token]' do
            subject { super()[:authenticity_token] }
            it { is_expected.to eq '1234567' }
          end

          describe '[:year]' do
            subject { super()[:year] }
            it { is_expected.to eq Date.today.year }
          end

          describe '[:month]' do
            subject { super()[:month] }
            it { is_expected.to eq Date.today.month }
          end

          describe '[:day]' do
            subject { super()[:day] }
            it { is_expected.to eq Date.today.day }
          end

          describe '[:from_accounts]' do
            subject { super()[:from_accounts] }
            it { is_expected.to eq [{ value: 'b', text: 'a' }, { value: 'd', text: 'c' }] }
          end

          describe '[:to_accounts]' do
            subject { super()[:to_accounts] }
            it { is_expected.to eq [{ value: 'f', text: 'e' }, { value: 'h', text: 'g' }] }
          end
        end
      end
    end
  end

  describe '#destroy' do
    context 'before login,' do
      before do
        xhr :delete, :destroy, id: 12_345
      end
      subject { response }
      it { is_expected.to redirect_by_js_to login_url }
    end

    context 'after login,' do
      let(:mock_user) { users(:user1) }
      before do
        mock_user
        expect(User).to receive(:find).with(mock_user.id).at_least(1).and_return(mock_user)
        dummy_login
      end

      context 'when id in params is invalid,' do
        let(:mock_items) { double }
        before do
          expect(mock_user).to receive(:items).and_return(mock_items)
          expect(mock_items).to receive(:find).with('12345').and_raise(ActiveRecord::RecordNotFound.new)
          xhr :delete, :destroy, id: 12_345
        end

        describe 'response' do
          subject { response }
          it { is_expected.to redirect_by_js_to current_entries_url }
        end
      end

      context "item's adjustment is false" do
        context "given there is a future's adjustment," do
          before do
            @old_item1 = items(:item1)
            @old_adj2 = items(:adjustment2)
            @old_bank1pl = monthly_profit_losses(:bank1200802)
            @old_expense3pl = monthly_profit_losses(:expense3200802)

            dummy_login

            xhr :delete, :destroy, id: @old_item1.id, year: @old_item1.action_date.year, month: @old_item1.action_date.month
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'the specified item' do
            subject { Item.where(id: @old_item1.id).load }
            it 'has no item' do
              expect(subject.size).to eq(0)
            end
          end

          describe 'the future adjustment item' do
            subject { Item.find(@old_adj2.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_adj2.amount - @old_item1.amount }
            end
          end

          describe 'amount of Montly profit loss of from_account' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_bank1pl.amount }
            end
          end

          describe 'amount of Montly profit loss of to_account' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:expense3200802).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_expense3pl.amount - @old_item1.amount }
            end
          end
        end

        context "given there is a future's adjustment whose id is to_account_id," do
          before do
            # prepare data to destroy
            xhr :post, :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/3', from_account_id: '2', to_account_id: '1' }, year: '2008', month: '2'
            @item_to_del = Item.where(action_date: Date.new(2008, 2, 3), from_account_id: 2, to_account_id: 1).first
            expect(@item_to_del.amount).to eq 1000

            @old_adj2 = items(:adjustment2)
            @old_bank1 = monthly_profit_losses(:bank1200802)
            @old_income = MonthlyProfitLoss.where(user_id: users(:user1).id, account_id: accounts(:income2).id, month: Date.new(2008, 2)).first

            dummy_login
            date = @item_to_del.action_date
            xhr :delete, :destroy, id: @item_to_del.id, year: date.year.to_s, month: date.month.to_s, day: date.day
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'the specified item' do
            subject { Item.where(id: @item_to_del.id).load }
            it 'has no item' do
              expect(subject.size).to eq(0)
            end
          end

          describe 'the future adjustment item' do
            subject { Item.find(@old_adj2.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_adj2.amount + @item_to_del.amount }
            end
          end

          describe 'amount of Montly profit loss of from_account' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_bank1.amount }
            end
          end

          describe 'amount of Montly profit loss of to_account' do
            subject { MonthlyProfitLoss.find(@old_income.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_income.amount + @item_to_del.amount }
            end
          end
        end

        context "given there is no future's adjustment," do
          before do
            dummy_login
            xhr :post, :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/25', from_account_id: '11', to_account_id: '13' }, year: 2008, month: 2
            @item = Item.where(name: 'test', from_account_id: 11, to_account_id: 13).first
            @old_bank11pl = MonthlyProfitLoss.where(account_id: 11, month: Date.new(2008, 2)).first
            @old_expense13pl = MonthlyProfitLoss.where(account_id: 13, month: Date.new(2008, 2)).first

            xhr :delete, :destroy, id: @item.id, year: 2008, month: 2
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'amount of from_account' do
            subject { MonthlyProfitLoss.find(@old_bank11pl.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_bank11pl.amount + @item.amount }
            end
          end

          describe 'specified item' do
            it 'should does not exist' do
              expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end

          describe 'amount of to_account' do
            subject { MonthlyProfitLoss.find(@old_expense13pl.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_expense13pl.amount - @item.amount }
            end
          end
        end

        context 'when destroy the item which is assigned to credit card account,' do
          context 'and payment date is in 2 months,' do
            let(:action) { -> { xhr :delete, :destroy, id: @item.id, year: 2008, month: 2 } }
            before do
              dummy_login
              # dummy data
              xhr :post, :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/10', from_account_id: '4', to_account_id: '3' }, year: 2008, month: 2
              @item = Item.where(name: 'test', from_account_id: 4, to_account_id: 3).first
              @child_item = @item.child_item
            end

            describe 'response' do
              before { action.call }
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'specified item' do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe 'child item of the specified item' do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@child_item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe 'profit_losses' do
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2)).sum(:amount) }.by(1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2)).sum(:amount) }.by(-1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4)).sum(:amount) }.by(1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4)).sum(:amount) }.by(-1_000) }
            end
          end

          context 'and payment date is in same months,' do
            let(:action) { -> { xhr :delete, :destroy, id: @item.id, year: 2008, month: 2 } }
            before do
              cr = credit_relations(:cr1)
              cr.update_attributes!(payment_month: 0, payment_day: 25, settlement_day: 11)

              dummy_login
              # dummy data
              xhr :post, :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/10', from_account_id: '4', to_account_id: '3' }, year: 2008, month: 2
              @item = Item.where(name: 'test', from_account_id: 4, to_account_id: 3).first
              @child_item = @item.child_item
            end

            describe 'response' do
              before { action.call }
              subject { response }
              it { is_expected.to be_success }

              describe '#content_type' do
                subject { super().content_type }
                it { is_expected.to eq 'text/javascript' }
              end
            end

            describe 'specified item' do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe 'future adjustment' do
              it { expect { action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(-1_000) }
            end

            describe 'profit_losses' do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2)).sum(:amount) } }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2)).sum(:amount) }.by(-1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 2)).sum(:amount) }.by(1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 3)).sum(:amount) }.by(-1_000) }
            end
          end
        end
      end

      context 'when adjustment is true,' do
        context 'with invalid id,' do
          let(:mock_items) { double }
          before do
            expect(mock_user).to receive(:items).and_return(mock_items)
            expect(mock_items).to receive(:find).with('20000').and_raise(ActiveRecord::RecordNotFound.new)
            xhr :delete, :destroy, id: 20_000, year: Date.today.year, month: Date.today.month
          end
          subject { response }
          it { is_expected.to redirect_by_js_to current_entries_url }
        end

        context 'with correct id,' do
          context "when change adj2's amount" do
            before do
              dummy_login

              @init_adj2 = Item.find(items(:adjustment2).id)
              @init_adj4 = Item.find(items(:adjustment4).id)
              @init_adj6 = Item.find(items(:adjustment6).id)
              @init_bank_pl = monthly_profit_losses(:bank1200802)
              @init_bank_pl = monthly_profit_losses(:bank1200802)
              @init_unknown_pl = MonthlyProfitLoss.where(month: Date.new(2008, 2), account_id: -1, user_id: users(:user1).id).first

              @action = -> { xhr :delete, :destroy, id: items(:adjustment2).id, year: 2008, month: 2 }
            end

            describe 'response' do
              before { @action.call }
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'specified item(adjustment2)' do
              before { @action.call }
              subject { Item.where(id: @init_adj2.id).first }
              it { is_expected.to be_nil }
            end

            describe 'adjustment4 which is next future adjustment' do
              it { expect { @action.call }.to change { Item.find(@init_adj4.id).amount }.by(@init_adj2.amount) }
            end

            describe 'bank_pl amount' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@init_bank_pl.id).amount } }
            end

            describe 'unknown pl amount' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@init_unknown_pl.id).amount } }
            end
          end

          context 'adj4を削除。影響をうけるのはadj6と,200802, 200803のm_pl' do
            before do
              dummy_login

              # データの初期化
              @init_adj2 = Item.find(items(:adjustment2).id)
              @init_adj4 = Item.find(items(:adjustment4).id)
              @init_adj6 = Item.find(items(:adjustment6).id)
              @init_bank_2_pl = monthly_profit_losses(:bank1200802)
              @init_bank_3_pl = monthly_profit_losses(:bank1200803)
              @init_unknown_2_pl = monthly_profit_losses(:unknown200802)
              @init_unknown_3_pl = monthly_profit_losses(:unknown200803)

              # 正常処理 (adj4を削除。影響をうけるのはadj6と,200802, 200803のm_pl)
              xhr :delete, :destroy, id: items(:adjustment4).id, year: 2008, month: 2
            end

            describe 'response' do
              subject { response }
              it { is_expected.to be_success }

              describe '#content_type' do
                subject { super().content_type }
                it { is_expected.to eq 'text/javascript' }
              end
            end

            describe 'previous adjustment(adj2)' do
              subject { Item.where(id: @init_adj2.id).first }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_adj2.amount }
              end
            end

            describe 'specified adjustment(adj4)' do
              subject { Item.find_by_id(@init_adj4.id) }
              it { is_expected.to be_nil }
            end

            describe 'next adjustment(adj6' do
              subject { Item.find_by_id(@init_adj6.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_adj6.amount + @init_adj4.amount }
              end
            end

            describe 'bank_2_pl' do
              subject { MonthlyProfitLoss.find(@init_bank_2_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_bank_2_pl.amount - @init_adj4.amount }
              end
            end

            describe 'bank_3_pl' do
              subject { MonthlyProfitLoss.find(@init_bank_3_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_bank_3_pl.amount + @init_adj4.amount }
              end
            end

            describe 'unknown_2_pl' do
              subject { MonthlyProfitLoss.find(@init_unknown_2_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_unknown_2_pl.amount + @init_adj4.amount }
              end
            end

            describe 'unknown_3_pl' do
              subject { MonthlyProfitLoss.find(@init_unknown_3_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_unknown_3_pl.amount - @init_adj4.amount }
              end
            end
          end

          context 'when destroying adj6 which effects no item/adjustment,' do
            before do
              dummy_login

              @init_adj2 = Item.find(items(:adjustment2).id)
              @init_adj4 = Item.find(items(:adjustment4).id)
              @init_adj6 = Item.find(items(:adjustment6).id)
              @init_bank_2_pl = monthly_profit_losses(:bank1200802)
              @init_bank_3_pl = monthly_profit_losses(:bank1200803)
              @init_unknown_2_pl = MonthlyProfitLoss.new
              @init_unknown_2_pl.month = Date.new(2008, 2)
              @init_unknown_2_pl.account_id = -1
              @init_unknown_2_pl.amount = 100
              @init_unknown_2_pl.user_id = users(:user1).id
              @init_unknown_2_pl.save!
              @init_unknown_3_pl = MonthlyProfitLoss.new
              @init_unknown_3_pl.month = Date.new(2008, 3)
              @init_unknown_3_pl.account_id = -1
              @init_unknown_3_pl.amount = 311
              @init_unknown_3_pl.user_id = users(:user1).id
              @init_unknown_3_pl.save!

              xhr :delete, :destroy, id: items(:adjustment6).id, year: 2008, month: 2
            end

            describe 'response' do
              subject { response }
              it { is_expected.to be_success }

              describe '#content_type' do
                subject { super().content_type }
                it { is_expected.to eq 'text/javascript' }
              end
            end

            describe 'the adj before last adj(adj2)' do
              subject { Item.find_by_id(@init_adj2.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_adj2.amount }
              end
            end

            describe 'the last adj(adj4)' do
              subject { Item.find_by_id(@init_adj4.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_adj4.amount }
              end
            end

            describe 'specified adjustment(adj6)' do
              subject { Item.find_by_id(@init_adj6.id) }
              it { is_expected.to be_nil }
            end

            describe 'bank_2_pl' do
              subject { MonthlyProfitLoss.find(@init_bank_2_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_bank_2_pl.amount }
              end
            end

            describe 'bank_3_pl' do
              subject { MonthlyProfitLoss.find(@init_bank_3_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq @init_bank_3_pl.amount - @init_adj6.amount }
              end
            end

            describe 'unknown_2' do
              subject { MonthlyProfitLoss.find(@init_unknown_2_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { @init_unknown_2_pl.amount }
              end
            end

            describe 'unknown_3' do
              subject { MonthlyProfitLoss.find(@init_unknown_3_pl.id) }

              describe '#amount' do
                subject { super().amount }
                it { @init_unknown_3_pl.amount + @init_adj6.amount }
              end
            end
          end
        end
      end
    end
  end

  describe '#create' do
    context 'before login,' do
      before do
        xhr :post, :create
      end

      subject { response }
      it { is_expected.to redirect_by_js_to login_url }
    end

    context 'after login, ' do
      before { dummy_login }

      context 'when validation errors happen,' do
        before do
          @previous_items = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: '', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_js_error id: 'warning', default_message: I18n.t('error.input_is_invalid') }
        end

        describe 'the count of items' do
          subject { Item.count }
          it { is_expected.to eq @previous_items }
        end
      end

      context 'when input action_year, action_month, action_day is specified,' do
        before do
          @previous_items = Item.count
          xhr :post, :create, entry: { action_year: Date.today.year.to_s, action_month: Date.today.month.to_s, action_day: Date.today.day.to_s, name: 'TEST11', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_js_error id: 'warning', default_message: I18n.t('error.input_is_invalid') }
        end

        describe 'the count of items' do
          subject { Item.count }
          it { is_expected.to eq @previous_items }
        end
      end

      context 'when input action_date is invalid,' do
        before do
          @previous_items = Item.count
          xhr :post, :create, entry: { action_date: 'xxxx/yy/dd', name: 'TEST11', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_js_error id: 'warning', default_message: I18n.t('error.date_is_invalid') }
        end

        describe 'the count of items' do
          subject { Item.count }
          it { is_expected.to eq @previous_items }
        end
      end

      shared_examples_for 'created successfully' do
        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
        end
      end

      context "when input amount's syntax is incorrect," do
        before do
          @previous_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'hogehoge', amount: '1+x', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month
        end
        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_js_error id: 'warning', default_message: I18n.t('error.amount_is_invalid') }
        end

        describe 'count of Item' do
          subject { Item.count }
          it { is_expected.to eq @previous_item_count }
        end
      end

      context '#create(only_add)' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'test10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, only_add: 'true'
        end

        it_should_behave_like 'created successfully'

        describe 'count of Item' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end
      end

      shared_examples_for "created successfully with tag_list == 'hoge fuga" do
        describe 'tags' do
          subject { Tag.where(name: 'hoge').load }
          it 'has 1 tag' do
            expect(subject.size).to eq(1)
          end
          specify do
            subject.each do |t|
              taggings = Tagging.where(tag_id: t.id).load
              expect(taggings.size).to eq 1
              taggings.each do |tag|
                expect(tag.user_id).to eq users(:user1).id
                expect(tag.taggable_type).to eq 'Item'
              end
            end
          end
        end
      end

      context 'with confirmation_required == true' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: 'true', tag_list: 'hoge fuga' }, year: Date.today.year.to_s, month: Date.today.month.to_s
        end

        it_should_behave_like 'created successfully'

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end

        describe 'created item' do
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq 'テスト10' }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq 10_000 }
          end
          it { is_expected.to be_confirmation_required }

          describe '#tag_list' do
            subject { super().tag_list }
            it { is_expected.to eq 'fuga hoge' }
          end
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga"
      end

      context 'with confirmation_required == true' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: 'true', tag_list: 'hoge fuga' }, year: Date.today.year.to_s, month: Date.today.month.to_s
        end

        it_should_behave_like 'created successfully'

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end

        describe 'created item' do
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq 'テスト10' }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq 10_000 }
          end
          it { is_expected.to be_confirmation_required }

          describe '#tag_list' do
            subject { super().tag_list }
            it { is_expected.to eq 'fuga hoge' }
          end
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga"
      end

      context 'with confirmation_required == nil' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga' }, year: Date.today.year.to_s, month: Date.today.month.to_s
        end

        it_should_behave_like 'created successfully'

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end

        describe 'created item' do
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq 'テスト10' }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq 10_000 }
          end
          it { is_expected.not_to be_confirmation_required }

          describe '#tag_list' do
            subject { super().tag_list }
            it { is_expected.to eq 'fuga hoge' }
          end
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga"
      end

      context "with year, month are not same as action_date's month" do
        before do
          @init_item_count = Item.count
          @display_month = 30.days.since(Date.today)
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga' }, year: @display_month.year.to_s, month: @display_month.month.to_s
        end

        it_should_behave_like 'created successfully'

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end

        describe 'created item' do
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq 'テスト10' }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq 10_000 }
          end
          it { is_expected.not_to be_confirmation_required }

          describe '#tag_list' do
            subject { super().tag_list }
            it { is_expected.to eq 'fuga hoge' }
          end
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga"

        describe '@items' do
          subject do
            assigns(:items).all? { |it| it.action_date.beginning_of_month == @display_month.beginning_of_month }
          end
          it { is_expected.to be_truthy }
        end
      end

      context 'when amount needs to be calcurated,' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '(10 + 10)/40*20', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: '' }, year: Date.today.year, month: Date.today.month
        end

        it_should_behave_like 'created successfully'

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count + 1 }
        end

        describe 'new record' do
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq 10 }
          end
        end
      end

      context 'when amount needs to be calcurated, but syntax error exists,' do
        before do
          @init_item_count = Item.count
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: 'テスト10', amount: '(10+20*2.01', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: '' }, year: Date.today.year, month: Date.today.month
        end

        describe 'response' do
          subject { response }
          it { is_expected.to render_js_error id: 'warning' }
        end

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count }
        end
      end

      context "with invalid params when only_add = 'true'," do
        before do
          @init_item_count = Item.count
          dummy_login
          xhr :post, :create, entry: { action_date: Date.today.strftime('%Y/%m/%d'), name: '', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, only_add: 'true'
        end

        describe 'response' do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_js_error id: 'warning' }
        end

        describe 'count of items' do
          subject { Item.count }
          it { is_expected.to eq @init_item_count }
        end
      end

      context 'with correct params,' do
        before do
          @init_adj2 = Item.find(items(:adjustment2).id)
          @init_adj4 = Item.find(items(:adjustment4).id)
          @init_adj6 = Item.find(items(:adjustment6).id)
          @init_pl0712 = monthly_profit_losses(:bank1200712)
          @init_pl0801 = monthly_profit_losses(:bank1200801)
          @init_pl0802 = monthly_profit_losses(:bank1200802)
          @init_pl0803 = monthly_profit_losses(:bank1200803)
          dummy_login
        end

        context 'created before adjustment which is in the same month,' do
          before do
            xhr(:post, :create,
                entry: {
                  action_date: @init_adj2.action_date.yesterday.strftime('%Y/%m/%d'),
                  name: 'テスト10',
                  amount: '10,000',
                  from_account_id: accounts(:bank1).id,
                  to_account_id: accounts(:expense3).id
                },
                year: 2008,
                month: 2)
          end

          it_should_behave_like 'created successfully'

          describe 'adjustment just next to the created item' do
            subject { Item.find(items(:adjustment2).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_adj2.amount + 10_000 }
            end
          end

          describe 'adjustment which is the next of the adjustment next to the created item' do
            subject { Item.find(items(:adjustment4).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_adj4.amount }
            end
          end

          describe 'adjustment which is the second next of the adjustment next to the created item' do
            subject { Item.find(items(:adjustment6).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_adj6.amount }
            end
          end

          describe 'monthly pl which is before the created item' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_pl0801.amount }
            end
          end

          describe 'monthly pl of the same month of the created item' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_pl0802.amount }
            end
          end

          describe 'monthly pl of the next month of the created item' do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @init_pl0803.amount }
            end
          end
        end

        context 'created between adjustments which both are in the same month of the item to create,' do
          before do
            @post = lambda {
              xhr(:post, :create,
                  entry: {
                    action_date: @init_adj4.action_date.yesterday.strftime('%Y/%m/%d'),
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'renderer' do
            before do
              @post.call
            end
            it_should_behave_like 'created successfully'
          end

          describe 'adjustment which is before the created item' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj2.id).amount } }
          end

          describe 'adjustment which is next to the created item in the same month' do
            it { expect { @post.call }.to change { Item.find(@init_adj4.id).amount }.by(10_000) }
          end

          describe 'adjustment which is second next to the created item in the next month' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj6.id).amount } }
          end

          describe "the adjusted account's monthly_pl of the last month of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
          end

          describe "the adjusted account's monthly_pl of the same month as that of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
          end

          describe "the adjusted account's monthly_pl of the next month of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end

          describe "the non-adjusted account's monthly_pl of the next month of the created item" do
            before do
              @post.call
            end
            subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
            it { is_expected.to be_nil }
          end

          describe "the non-adjusted account's monthly_pl of the same month as the created item" do
            it { expect { @post.call }.to change { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
          end
        end

        context 'created between adjustments, and the one is on earlier date in the same month and the other is in the next month of the item to create,' do
          # adj4とadj6の間(adj4と同じ月)
          before do
            @post = lambda {
              xhr(:post, :create,
                  entry: {
                    action_date: @init_adj4.action_date.tomorrow.strftime('%Y/%m/%d'),
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'renderer' do
            before do
              @post.call
            end
            it_should_behave_like 'created successfully'
          end

          describe 'the adjustment of the month before the item' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj2.id).amount } }
          end

          describe 'the adjustments of the date before the item' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj2.id).amount } }
            it { expect { @post.call }.not_to change { Item.find(@init_adj4.id).amount } }
          end

          describe 'the adjustments of the next of item' do
            it { expect { @post.call }.to change { Item.find(@init_adj6.id).amount }.by(10_000) }
          end

          describe "the adjusted account's monthly_pl of the last month of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
          end

          describe "the adjusted account's monthly_pl of the same month as that of the created item" do
            it { expect { @post.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount }.by(-10_000) }
          end

          describe "the adjusted account's monthly_pl of the next month of the created item" do
            it { expect { @post.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(10_000) }
          end

          describe "the non-adjusted account's monthly_pl of the next month of the created item" do
            before do
              @post.call
            end
            subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
            it { is_expected.to be_nil }
          end

          describe "the non-adjusted account's monthly_pl of the same month as the created item" do
            it { expect { @post.call }.to change { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
          end
        end

        context "created between adjustments, and the one of next item's date is in the same month and the other is in the previous month of the item to create," do
          before do
            @post = lambda {
              xhr(:post, :create,
                  entry: {
                    action_date: @init_adj6.action_date.yesterday.strftime('%Y/%m/%d'),
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'renderer' do
            before do
              @post.call
            end
            it_should_behave_like 'created successfully'
          end

          describe 'the adjustment of the month before the item' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj2.id).amount } }
            it { expect { @post.call }.not_to change { Item.find(@init_adj4.id).amount } }
          end

          describe 'the adjustments of the next of item' do
            it { expect { @post.call }.to change { Item.find(@init_adj6.id).amount }.by(10_000) }
          end

          describe "the adjusted account's monthly_pl of the last month or before of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }

            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
          end

          describe "the adjusted account's monthly_pl of the same month as that of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end

          describe "the non-adjusted account's monthly_pl of the same month as the created item which does not exist before." do
            before do
              @post.call
            end
            subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first.amount }
            it { is_expected.to eq 10_000 }
          end
        end

        context "created after any adjustments, and the one of last item's date is in the same month and the other is in the previous month of the item to create," do
          # after adj6
          before do
            @post = lambda {
              xhr(:post, :create,
                  entry: {
                    action_date: @init_adj6.action_date.tomorrow.strftime('%Y/%m/%d'),
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'renderer' do
            before do
              @post.call
            end
            it_should_behave_like 'created successfully'
          end

          describe 'the adjustments before the item' do
            it { expect { @post.call }.not_to change { Item.find(@init_adj2.id).amount } }
            it { expect { @post.call }.not_to change { Item.find(@init_adj4.id).amount } }
            it { expect { @post.call }.not_to change { Item.find(@init_adj6.id).amount } }
          end

          describe "the adjusted account's monthly_pl of the last month or before of the created item" do
            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }

            it { expect { @post.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
          end

          describe "the adjusted account's monthly_pl of the same month as that of the created item" do
            it { expect { @post.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(-10_000) }
          end

          describe "the non-adjusted account's monthly_pl of the same month as the created item which does not exist before." do
            before do
              @post.call
            end
            subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first.amount }
            it { is_expected.to eq 10_000 }
          end
        end
      end

      describe 'credit card payment' do
        context 'created item with credit card, purchased before the settlement date of the month' do
          before do
            dummy_login
            xhr(:post, :create,
                entry: {
                  action_date: '2008/02/10',
                  name: 'テスト10',
                  amount: '10,000',
                  from_account_id: accounts(:credit4).id,
                  to_account_id: accounts(:expense3).id
                },
                year: 2008,
                month: 2)
          end

          let(:credit_item) do
            Item.where(action_date: Date.new(2008, 2, 10),
                       from_account_id: accounts(:credit4).id,
                       to_account_id: accounts(:expense3).id,
                       amount: 10_000,
                       parent_id: nil).find(&:child_item)
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'created credit item' do
            subject { credit_item }
            it { is_expected.not_to be_nil }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 10_000 }
            end

            describe '#parent_id' do
              subject { super().parent_id }
              it { is_expected.to be_nil }
            end

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.not_to be_nil }
            end
          end

          describe "child item's count" do
            subject { Item.where(parent_id: credit_item.id) }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq 1 }
            end
          end

          describe 'child item' do
            subject { Item.where(parent_id: credit_item.id).find { |i| i.child_item.nil? } }

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.to be_nil }
            end

            describe '#parent_item' do
              subject { super().parent_item }
              it { is_expected.to eq credit_item }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.new(2008, 2 + credit_relations(:cr1).payment_month, credit_relations(:cr1).payment_day) }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq credit_relations(:cr1).payment_account_id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq credit_relations(:cr1).credit_account_id }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 10_000 }
            end
          end
        end

        context 'created item with credit card, purchased before the settlement date of the month' do
          before do
            dummy_login
            cr1 = credit_relations(:cr1)
            cr1.settlement_day = 15
            expect(cr1.save).to be_truthy

            xhr(:post, :create,
                entry: {
                  action_date: '2008/02/25',
                  name: 'テスト10',
                  amount: '10,000',
                  from_account_id: accounts(:credit4).id,
                  to_account_id: accounts(:expense3).id
                },
                year: 2008,
                month: 2)
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          let(:credit_item) do
            Item.where(action_date: Date.new(2008, 2, 25),
                       from_account_id: accounts(:credit4).id,
                       to_account_id: accounts(:expense3).id,
                       amount: 10_000, parent_id: nil).find(&:child_item)
          end

          describe 'created credit item' do
            subject { credit_item }
            it { is_expected.not_to be_nil }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 10_000 }
            end

            describe '#parent_id' do
              subject { super().parent_id }
              it { is_expected.to be_nil }
            end

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.not_to be_nil }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.new(2008, 2, 25) }
            end
          end

          describe 'child item' do
            describe 'child item count' do
              subject { Item.where(parent_id: credit_item.id) }

              describe '#count' do
                subject { super().count }
                it { is_expected.to eq 1 }
              end
            end

            describe 'child item' do
              subject { Item.where(parent_id: credit_item.id).first }

              describe '#child_item' do
                subject { super().child_item }
                it { is_expected.to be_nil }
              end

              describe '#parent_id' do
                subject { super().parent_id }
                it { is_expected.to eq credit_item.id }
              end

              describe '#id' do
                subject { super().id }
                it { is_expected.to eq credit_item.child_item.id }
              end

              describe '#action_date' do
                subject { super().action_date }
                it { is_expected.to eq Date.new(2008, 3 + credit_relations(:cr1).payment_month, credit_relations(:cr1).payment_day) }
              end

              describe '#from_account_id' do
                subject { super().from_account_id }
                it { is_expected.to eq credit_relations(:cr1).payment_account_id }
              end

              describe '#to_account_id' do
                subject { super().to_account_id }
                it { is_expected.to eq credit_relations(:cr1).credit_account_id }
              end

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq 10_000 }
              end
            end
          end
        end

        context 'created item with credit card, whose settlement_date == 99' do
          before do
            @cr1 = credit_relations(:cr1)
            @cr1.payment_day = 99
            expect(@cr1.save).to be_truthy
            dummy_login

            xhr(:post, :create,
                entry: {
                  action_date: '2008/2/10',
                  name: 'テスト10',
                  amount: '10,000',
                  from_account_id: accounts(:credit4).id,
                  to_account_id: accounts(:expense3).id
                },
                year: 2008,
                month: 2)
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          let(:credit_item) do
            Item.where(action_date: Date.new(2008, 2, 10),
                       from_account_id: accounts(:credit4).id,
                       to_account_id: accounts(:expense3).id,
                       amount: 10_000, parent_id: nil).find(&:child_item)
          end

          describe 'created credit item' do
            subject { credit_item }
            it { is_expected.not_to be_nil }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 10_000 }
            end

            describe '#parent_id' do
              subject { super().parent_id }
              it { is_expected.to be_nil }
            end

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.not_to be_nil }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.new(2008, 2, 10) }
            end
          end

          describe "child item's count" do
            subject { Item.where(parent_id: credit_item.id) }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq 1 }
            end
          end

          describe 'child item' do
            subject { Item.where(parent_id: credit_item.id).first }

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.to be_nil }
            end

            describe '#parent_id' do
              subject { super().parent_id }
              it { is_expected.to eq credit_item.id }
            end

            describe '#id' do
              subject { super().id }
              it { is_expected.to eq credit_item.child_item.id }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq Date.new(2008, 2 + @cr1.payment_month, 1).end_of_month }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq @cr1.payment_account_id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq @cr1.credit_account_id }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 10_000 }
            end
          end
        end
      end

      describe 'balance adjustment' do
        context 'action_year/month/day is set,' do
          it { expect { xhr :post, :create, entry: { action_year: '2008', action_month: '2', action_day: '5', from_account_id: '-1', to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000', entry_type: 'adjustment' }, year: 2008, month: 2 }.not_to change { Item.count } }
        end

        context 'when a validation error occurs,' do
          before do
            mock_exception = ActiveRecord::RecordInvalid.new(stub_model(Item))
            mock_errors = double
            mock_record = double
            expect(mock_errors).to receive(:full_messages).and_return(['Error!!!'])
            expect(mock_record).to receive(:errors).and_return(mock_errors)
            expect(mock_exception).to receive(:record).and_return(mock_record)
            expect(Teller).to receive(:create_entry).and_raise(mock_exception)
            @action = lambda {
              xhr :post, :create, entry: { action_date: '2008/02/05', from_account_id: '-1', to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000', entry_type: 'adjustment' }, year: 2008, month: 2
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
            it { is_expected.to render_js_error id: 'warning' }
          end
        end

        context 'with invalid calcuration amount,' do
          let(:date) { items(:adjustment2).action_date - 1 }
          it { expect { xhr :post, :create, entry: { entry_type: 'adjustment', action_date: date.strftime('%Y/%m/%d'), to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000-(10' }, year: 2008, month: 2 }.not_to change { Item.count } }
        end

        context 'add adjustment before any of the adjustments,' do
          before do
            dummy_login
            @date = items(:adjustment2).action_date - 1
            @action = lambda {
              xhr(:post, :create,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: @date.strftime('%Y/%m/%d'),
                    to_account_id: accounts(:bank1).id.to_s,
                    adjustment_amount: '100*(10+50)/2',
                    tag_list: 'hoge fuga'
                  },
                  year: '2008',
                  month: '3')
            }
          end

          describe 'count of Item' do
            it { expect { @action.call }.to change { Item.count }.by(1) }
          end

          describe '@items' do
            before { @action.call }

            subject { assigns(:items).all? { |it| (Date.new(2008, 3, 1)..Date.new(2008, 3, 31)).cover?(it.action_date) } }
            it { is_expected.to be_truthy }
          end

          describe 'created adjustment' do
            before do
              account_id = accounts(:bank1).id
              init_items = Item.where('action_date <= ?', @date)
              @init_total = init_items.where(to_account_id: account_id).sum(:amount) - init_items.where(from_account_id: account_id).sum(:amount)
              @action.call
              @created_item = Item.where(user_id: users(:user1).id, action_date: @date).order('id desc').first
              prev_items = Item.where('id < ?', @created_item.id).where('action_date <= ?', @date)
              @prev_total = prev_items.where(to_account_id: account_id).sum(:amount) - prev_items.where(from_account_id: account_id).sum(:amount)
            end
            subject { @created_item }

            it { is_expected.to be_adjustment }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 100 * (10 + 50) / 2 }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 100 * (10 + 50) / 2 - @prev_total }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 100 * (10 + 50) / 2 - @init_total }
            end

            describe '#tag_list' do
              subject { super().tag_list }
              it { is_expected.to eq 'fuga hoge' }
            end
          end

          describe 'profit losses' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end

          describe 'tag' do
            it { expect { @action.call }.to change { Tag.where(name: 'hoge').count }.by(1) }
            it { expect { @action.call }.to change { Tag.where(name: 'fuga').count }.by(1) }
          end

          describe 'taggings' do
            it { expect { @action.call }.to change { Tagging.where(user_id: users(:user1).id, taggable_type: 'Item').count }.by(2) }
          end
        end

        context "create adjustment to the same day as another ajustment's one," do
          context 'input values are valid,' do
            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) do
              lambda {
                date = existing_adj.action_date
                xhr(:post, :create,
                    entry: {
                      entry_type: 'adjustment',
                      action_date: date.strftime('%Y/%m/%d'),
                      to_account_id: accounts(:bank1).id.to_s,
                      adjustment_amount: '50'
                    },
                    year: 2008,
                    month: 2)
              }
            end
            describe 'created_adjustment' do
              before { action.call }
              subject { Adjustment.where(action_date: existing_adj.action_date).first }

              describe '#adjustment_amount' do
                subject { super().adjustment_amount }
                it { is_expected.to eq 50 }
              end

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq existing_adj.amount + 50 - existing_adj.adjustment_amount }
              end
            end

            describe 'existed adjustment' do
              before { action.call }
              subject { Item.find_by_id(existing_adj.id) }
              it { is_expected.to be_nil }
            end

            describe 'future adjustment' do
              it { expect { action.call }.to change { Item.find(future_adj.id).amount }.by(existing_adj.adjustment_amount - 50) }
            end

            describe 'monthly_pl' do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end

          context 'input values are invalid,' do
            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) do
              lambda {
                date = existing_adj.action_date
                xhr(:post, :create,
                    entry: {
                      entry_type: 'adjustment',
                      action_date: date.strftime('%Y/%m/%d'),
                      to_account_id: accounts(:bank1).id.to_s, adjustment_amount: 'SDSFSAF * xdfa'
                    },
                    year: 2008,
                    month: 2)
              }
            end

            describe 'response' do
              before { action.call }
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'all adjustments count' do
              it { expect { action.call }.not_to change { Adjustment.count } }
            end
            describe 'all item count' do
              it { expect { action.call }.not_to change { Item.count } }
            end

            describe 'existing_adj' do
              it { expect { action.call }.not_to change { Item.find(existing_adj.id).amount } }
            end

            describe 'future adjustment' do
              it { expect { action.call }.not_to change { Item.find(future_adj.id).amount } }
            end

            describe 'profit_losses' do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end

          context 'input action_year/month/day is specified,' do
            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) do
              lambda {
                date = existing_adj.action_date
                xhr(:post, :create,
                    entry: {
                      entry_type: 'adjustment',
                      action_year: date.year,
                      action_month: date.month,
                      action_day: date.day,
                      to_account_id: accounts(:bank1).id.to_s,
                      adjustment_amount: '50000'
                    },
                    year: 2008,
                    month: 2)
              }
            end

            describe 'response' do
              before { action.call }
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'all adjustments count' do
              it { expect { action.call }.not_to change { Adjustment.count } }
            end
            describe 'all item count' do
              it { expect { action.call }.not_to change { Item.count } }
            end

            describe 'existing_adj' do
              it { expect { action.call }.not_to change { Item.find(existing_adj.id).amount } }
            end

            describe 'future adjustment' do
              it { expect { action.call }.not_to change { Item.find(future_adj.id).amount } }
            end

            describe 'profit_losses' do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end
        end

        context 'create adjustment between adjustments whose months are same,' do
          let(:date) { items(:adjustment4).action_date - 1 }
          let(:next_adj_date) { items(:adjustment4).action_date }
          let(:action) do
            lambda {
              xhr(:post, :create,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    to_account_id: accounts(:bank1).id.to_s,
                    adjustment_amount: '3000'
                  },
                  year: '2008',
                  month: '2')
            }
          end

          before do
            @amount_before = total_amount_to(date)
            dummy_login
          end

          describe 'response' do
            before do
              action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'count of items' do
            it { expect { action.call }.to change { Item.count }.by(1) }
          end

          describe 'created adjustment' do
            before do
              action.call
              @created_adj = Adjustment.where(user_id: users(:user1).id, action_date: date, to_account_id: accounts(:bank1).id).first
            end
            subject { @created_adj }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq(-1) }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @amount_before }
            end
          end

          def total_amount_to(the_date)
            common_cond = Item.where('action_date <= ?', the_date).where(user_id: users(:user1).id)
            common_cond.where(to_account_id: accounts(:bank1).id).sum(:amount) - common_cond.where(from_account_id: accounts(:bank1).id).sum(:amount)
          end

          describe 'total of amounts to the date' do
            before do
              action.call
            end
            subject { total_amount_to(date) }
            it { is_expected.to eq 3000 }
          end

          describe 'total of amounts to the date which has the next adjustment' do
            before do
              action.call
            end
            subject { total_amount_to(next_adj_date) }
            it { is_expected.to eq items(:adjustment4).adjustment_amount }
          end

          describe 'profit losses' do
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end
        end

        context 'create adjustment between adjustments whose months are different and created item is of the same month of earlier one,' do
          let(:date) { items(:adjustment4).action_date + 1 }
          let(:next_adj_date) { items(:adjustment6).action_date }
          let(:action) do
            lambda {
              xhr(:post, :create,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    to_account_id: accounts(:bank1).id.to_s,
                    adjustment_amount: '3000'
                  },
                  year: 2008,
                  month: 2)
            }
          end

          before do
            @amount_before = total_amount_to(date)
            dummy_login
          end
          describe 'response' do
            before do
              action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'count of items' do
            it { expect { action.call }.to change { Item.count }.by(1) }
          end

          def total_amount_to(the_date)
            common_cond = Item.where('action_date <= ?', the_date).where(user_id: users(:user1).id)
            common_cond.where(to_account_id: accounts(:bank1).id).sum(:amount) - common_cond.where(from_account_id: accounts(:bank1).id).sum(:amount)
          end

          describe 'created adjustment' do
            before do
              action.call
              @created_adj = Adjustment.where(user_id: users(:user1).id, action_date: date, to_account_id: accounts(:bank1).id).first
            end
            subject { @created_adj }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq(-1) }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @amount_before }
            end
          end

          describe 'next adjustment' do
            it { expect { action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(@amount_before - 3000) }
          end

          describe 'total of amounts to the date' do
            before do
              action.call
            end
            subject { total_amount_to(date) }
            it { is_expected.to eq 3000 }
          end

          describe 'total of amounts to the date which has the next adjustment' do
            before do
              action.call
            end
            subject { total_amount_to(next_adj_date) }
            it { is_expected.to eq items(:adjustment6).adjustment_amount }
          end

          describe 'profit losses' do
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount }.by(3000 - @amount_before) }
            it { expect { action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(@amount_before - 3000) }
          end
        end

        context 'create adjustment between adjustments whose months are different and created item is of the same month of later one,' do
          let(:date) { items(:adjustment6).action_date - 1 }
          let(:next_adj_date) { items(:adjustment6).action_date }
          let(:action) do
            lambda {
              xhr(:post, :create,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    to_account_id: accounts(:bank1).id.to_s,
                    adjustment_amount: '3000'
                  },
                  year: 2008.to_s,
                  month: 2.to_s)
            }
          end

          before do
            @amount_before = total_amount_to(date)
            dummy_login
          end
          describe 'response' do
            before do
              action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'count of items' do
            it { expect { action.call }.to change { Item.count }.by(1) }
          end

          def total_amount_to(the_date)
            common_cond = Item.where('action_date <= ?', the_date).where(user_id: users(:user1).id)
            common_cond.where(to_account_id: accounts(:bank1).id).sum(:amount) - common_cond.where(from_account_id: accounts(:bank1).id).sum(:amount)
          end

          describe 'created adjustment' do
            before do
              action.call
              @created_adj = Adjustment.where(user_id: users(:user1).id, action_date: date, to_account_id: accounts(:bank1).id).first
            end
            subject { @created_adj }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq(-1) }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @amount_before }
            end
          end

          describe 'next adjustment' do
            it { expect { action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(@amount_before - 3000) }
          end

          describe 'total of amounts to the date' do
            before do
              action.call
            end
            subject { total_amount_to(date) }
            it { is_expected.to eq 3000 }
          end

          describe 'total of amounts to the date which has the next adjustment' do
            before do
              action.call
            end
            subject { total_amount_to(next_adj_date) }
            it { is_expected.to eq items(:adjustment6).adjustment_amount }
          end

          describe 'profit losses' do
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end
        end

        context 'create adjustment after all adjustments,' do
          let(:date) { items(:adjustment6).action_date + 1 }
          let(:action) do
            lambda {
              xhr(:post, :create,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    to_account_id: accounts(:bank1).id.to_s,
                    adjustment_amount: '3000'
                  },
                  year: 2008,
                  month: 2)
            }
          end

          before do
            @amount_before = total_amount_to(date)
            dummy_login
          end
          describe 'response' do
            before do
              action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'count of items' do
            it { expect { action.call }.to change { Item.count }.by(1) }
          end

          def total_amount_to(the_date)
            common_cond = Item.where('action_date <= ?', the_date).where(user_id: users(:user1).id)
            common_cond.where(to_account_id: accounts(:bank1).id).sum(:amount) - common_cond.where(from_account_id: accounts(:bank1).id).sum(:amount)
          end

          describe 'created adjustment' do
            before do
              action.call
              @created_adj = Adjustment.where(user_id: users(:user1).id, action_date: date, to_account_id: accounts(:bank1).id).first
            end
            subject { @created_adj }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq(-1) }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @amount_before }
            end
          end

          describe 'total of amounts to the date' do
            before do
              action.call
            end
            subject { total_amount_to(date) }
            it { is_expected.to eq 3000 }
          end

          describe 'profit losses' do
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(3000 - @amount_before) }
          end
        end
      end
    end
  end

  describe '#update' do
    context 'before login,' do
      before do
        xhr(:put, :update,
            entry: {
              entry_type: 'adjustment',
              adjustment_amoount: '500'
            },
            year: Date.today.year,
            month: Date.today.month,
            id: items(:adjustment2).id.to_s)
      end

      describe 'response' do
        subject { response }
        it { is_expected.to redirect_by_js_to login_url }
      end
    end

    context 'after login,' do
      before { dummy_login }

      describe 'update adjustment' do
        context 'without params[:to_account_id]' do
          before do
            date = items(:adjustment2).action_date
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id.to_s,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000'
                  },
                  year: 2008,
                  month: 2)
            }
          end
          describe 'response' do
            before do
              @action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'item to update' do
            it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).updated_at } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).adjustment_amount }.to(3000) }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).from_account_id } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).to_account_id } }
          end
        end

        context 'with invalid function for amount' do
          before do
            dummy_login
            date = items(:adjustment2).action_date
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '(20*30)/(10+1',
                    to_account_id: items(:adjustment2).to_account_id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'item to update' do
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).amount } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).adjustment_amount } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).updated_at } }
          end
        end

        context 'with changing action_date which alredy has another adjustment of the same account' do
          before do
            dummy_login
            date = items(:adjustment4).action_date
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '300',
                    to_account_id: items(:adjustment4).to_account_id
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_js_error id: "item_warning_#{items(:adjustment2).id}" }
          end

          describe 'item to update' do
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).amount } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).adjustment_amount } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).updated_at } }
          end
        end

        context 'with changing only amount' do
          before do
            @old_adj2 = items(:adjustment2)
            @old_adj4 = items(:adjustment4)
            @old_adj6 = items(:adjustment6)
            @old_m_pl_bank1_200802 = monthly_profit_losses(:bank1200802)

            date = items(:adjustment2).action_date

            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '(10+50)*200/4',
                    to_account_id: items(:adjustment2).to_account_id,
                    tag_list: 'hoge fuga'
                  },
                  year: 2008,
                  month: 2,
                  tag_list: 'hoge fuga')
            }
          end

          describe 'response' do
            before do
              @action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            before do
              @action.call
            end
            subject { Item.find(@old_adj2.id) }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @old_adj2.action_date }
            end
            it { is_expected.to be_adjustment }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @old_adj2.adjustment_amount + @old_adj2.amount }
            end

            describe '#tag_list' do
              subject { super().tag_list }
              it { is_expected.to eq 'fuga hoge' }
            end
          end

          describe 'the adjustment item next to the updated item' do
            before do
              @action.call
            end
            subject { Item.find(@old_adj4.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_adj4.amount + @old_adj2.adjustment_amount - 3000 }
            end
          end

          describe 'the adjustment item second next to the updated item' do
            before do
              @action.call
            end
            subject { Item.find(@old_adj6.id) }

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq @old_adj6.amount }
            end
          end

          describe 'monthly pl' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
          end
        end

        context 'when there is no future adjustment,' do
          before do
            @old_adj6 = items(:adjustment6)
            date = items(:adjustment6).action_date
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment6).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: items(:adjustment6).to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).updated_at } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment6).id).action_date } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment6).id).adjustment? } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).adjustment_amount }.to(3000) }
            it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(3000 - @old_adj6.adjustment_amount) }
          end

          describe 'other adjustments' do
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).amount } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).amount } }
          end

          describe 'monthly pl' do
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(3000 - @old_adj6.adjustment_amount) }
          end
        end

        #
        # 日付に変更がなく、未来のadjが存在するが、当月ではない場合
        #
        context 'when change amount the adjustment which has an adjustment in the next month' do
          before do
            @old_adj4 = items(:adjustment4)
            date = @old_adj4.action_date
            # 金額のみ変更
            @action = lambda {
              xhr(:put, :update,
                  id: @old_adj4.id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: @old_adj4.to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).updated_at } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).action_date } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).adjustment? } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).adjustment_amount }.to(3000) }
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).amount }.by(3000 - @old_adj4.adjustment_amount) }
          end

          describe 'other adjustments' do
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).amount } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(@old_adj4.adjustment_amount - 3000) }
          end

          describe 'monthly pl' do
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount }.by(3000 - @old_adj4.adjustment_amount) }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(@old_adj4.adjustment_amount - 3000) }
          end
        end

        context 'when change date,' do
          before do
            @init_adj2 = items(:adjustment2)
            @date = date = items(:adjustment4).action_date - 1

            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: items(:adjustment2).to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before do
              @action.call
            end
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            def item
              Item.find(items(:adjustment2).id)
            end
            it { expect { @action.call }.to change { item.adjustment_amount }.to(3000) }
            it { expect { @action.call }.to change { item.action_date }.to(@date) }
            it { expect { @action.call }.not_to change { item.adjustment? } }
            it { expect { @action.call }.to change { item.amount }.by(3000 - @init_adj2.adjustment_amount) }
          end

          describe 'other adjustment items' do
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).amount }.by(@init_adj2.adjustment_amount - 3000) }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment6).id).amount } }
          end

          describe 'monthly pls' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end
        end

        context 'when account_id is changed,' do
          let(:adj2_id) { items(:adjustment2).id }
          let(:adj4_id) { items(:adjustment4).id }
          before do
            @old_adj2 = old_adj2 = items(:adjustment2)
            @old_adj4 = old_adj4 = items(:adjustment4)
            @old_adj6 = old_adj6 = items(:adjustment6)
            xhr(:post, :create,
                entry: {
                  entry_type: 'adjustment',
                  action_date: old_adj6.action_date.strftime('%Y/%m/%d'),
                  to_account_id: 13, adjustment_amount: '1000'
                },
                year: old_adj4.action_date.year,
                month: old_adj4.action_date.month)
            @future_adj = Adjustment.where(action_date: old_adj6.action_date, to_account_id: 13).first
            @date = date = old_adj2.action_date
            @old_mpl = MonthlyProfitLoss.where(month: date.beginning_of_month, account_id: old_adj2.to_account_id).first
            @new_mpl = MonthlyProfitLoss.where(month: date.beginning_of_month, account_id: 13).first
            @new_adj_mpl = MonthlyProfitLoss.where(month: old_adj6.action_date.beginning_of_month, account_id: 13).first
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: 13
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated adjustment' do
            before { @action.call }
            subject { Item.find(adj2_id) }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @date }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { 13 }
            end
          end

          describe "updated adjustment's amount change" do
            let(:total) do
              scoped_items = Item.where('action_date < ?', @date)
              scoped_items.where(to_account_id: 13).sum(:amount) - scoped_items.where(from_account_id: 13).sum(:amount)
            end
            it { expect { @action.call }.to change { Item.find(adj2_id).amount }.from(@old_adj2.amount).to(3000 - total) }
          end

          describe 'the future adjustment which has an old account_id' do
            it { expect { @action.call }.to change { Item.find(adj4_id).amount }.by(@old_adj2.amount) }
          end

          describe 'the future adjustment which has an new account_id' do
            let(:total) do
              scoped_items = Item.where('action_date < ?', @date)
              scoped_items.where(to_account_id: 13).sum(:amount) - scoped_items.where(from_account_id: 13).sum(:amount)
            end
            it { expect { @action.call }.to change { Item.find(@future_adj.id).amount }.by(total - 3000) }
          end

          describe 'profit losses' do
            describe 'pl of old account' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@old_mpl.id).amount } }
            end

            describe 'pl of new account' do
              let(:total) do
                scoped_items = Item.where('action_date < ?', @date)
                scoped_items.where(to_account_id: 13).sum(:amount) - scoped_items.where(from_account_id: 13).sum(:amount)
              end
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(month: @old_adj2.action_date.beginning_of_month, account_id: 13).first.try(:amount).to_i }.by(3000 - total) }
            end

            describe 'pl of new account' do
              let(:total) do
                scoped_items = Item.where('action_date < ?', @date)
                scoped_items.where(to_account_id: 13).sum(:amount) - scoped_items.where(from_account_id: 13).sum(:amount)
              end
              it { expect { @action.call }.to change { MonthlyProfitLoss.find(@new_adj_mpl.id).amount }.by(total - 3000) }
            end
          end
        end

        context 'when action_date is changed to the next month and before adjustment,' do
          let(:date) { items(:adjustment6).action_date - 1 }
          before do
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: items(:adjustment2).to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated adjustment' do
            before { @action.call }
            subject { Item.find(items(:adjustment2).id) }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end
            it { is_expected.to be_adjustment }

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq date }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - Account.asset(users(:user1), items(:adjustment2).to_account_id, date, items(:adjustment2).id) }
            end
          end

          describe 'other adjustments' do
            describe 'adjustment4' do
              before { @old_adj2 = items(:adjustment2) }
              it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).amount }.by(@old_adj2.amount) }
            end

            describe 'adjustment6' do
              before { @old_adj6 = items(:adjustment6) }
              it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).amount }.to(@old_adj6.adjustment_amount - 3000) }
            end
          end

          describe 'balance' do
            it { expect { @action.call }.not_to change { Account.asset(users(:user1), items(:adjustment2).to_account_id, items(:adjustment4).action_date) } }
            it { expect { @action.call }.not_to change { Account.asset(users(:user1), items(:adjustment2).to_account_id, items(:adjustment6).action_date) } }

            describe 'balance at new adjustment2 date' do
              before { @action.call }
              subject { Account.asset(users(:user1), items(:adjustment2).to_account_id, date) }
              it { is_expected.to eq 3000 }
            end
          end

          describe 'profit losses' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(month: Date.new(2008, 2), account_id: items(:adjustment2).to_account_id).first.amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(month: Date.new(2008, 3), account_id: items(:adjustment2).to_account_id).first.amount } }
          end
        end

        context "when updating adjustment's action_date to the next month and there is no other adjustments in the future," do
          let(:updated_id) { items(:adjustment2).id }
          before do
            @init_adj2 = items(:adjustment2)
            @init_adj4 = items(:adjustment4)
            @init_adj6 = items(:adjustment6)

            date = items(:adjustment6).action_date + 1
            @action = lambda {
              xhr(:put, :update,
                  id: items(:adjustment2).id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: items(:adjustment2).to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }

            it { is_expected.to be_success }
          end

          describe 'updated item' do
            before do
              @action.call
            end

            subject { Item.find(updated_id) }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - Item.find(@init_adj6.id).adjustment_amount }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @init_adj6.action_date.tomorrow }
            end
            it { is_expected.to be_adjustment }
          end

          describe 'the adjustment which was next to updated adjustment' do
            it { expect { @action.call }.to change { Item.find(@init_adj4.id).amount }.by(@init_adj2.amount) }
          end

          describe 'the adjustment which is in front of updated adjustment' do
            it { expect { @action.call }.not_to change { Item.find(@init_adj6.id).amount } }
          end

          describe 'monthly profit losses' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(3000 - @init_adj6.adjustment_amount) }
          end
        end

        context "when updating adjustment's action_date which doesn't have future adjsutment to the previous month and now there is other adjustments in the future," do
          let(:updated_id) { items(:adjustment6).id }
          let(:date) { items(:adjustment2).action_date.yesterday }
          before do
            @init_adj2 = items(:adjustment2)
            @init_adj4 = items(:adjustment4)
            @init_adj6 = items(:adjustment6)

            @action = lambda {
              xhr(:put, :update,
                  id: updated_id,
                  entry: {
                    entry_type: 'adjustment',
                    action_date: date.strftime('%Y/%m/%d'),
                    adjustment_amount: '3,000',
                    to_account_id: items(:adjustment6).to_account_id
                  },
                  year: date.year,
                  month: date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }

            it { is_expected.to be_success }
          end

          describe 'updated item' do
            before do
              @action.call
              @asset = Account.asset(users(:user1), @init_adj6.to_account_id, date, updated_id)
            end

            subject { Item.find(updated_id) }

            describe '#adjustment_amount' do
              subject { super().adjustment_amount }
              it { is_expected.to eq 3000 }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 3000 - @asset }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq date }
            end
            it { is_expected.to be_adjustment }
          end

          describe 'the adjustment which is next to updated adjustment' do
            before { @asset = Account.asset(users(:user1), @init_adj6.to_account_id, date, updated_id) }
            it { expect { @action.call }.to change { Item.find(@init_adj2.id).amount }.by(@asset - 3000) }
          end

          describe 'monthly profit losses' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(-1 * @init_adj6.amount) }
          end
        end
      end

      describe 'update item' do
        context 'with missing params' do
          before do
            @action = -> { xhr :put, :update, id: items(:item1).id, year: 2008, month: 2 }
          end

          describe 'item to update' do
            it { expect { @action.call }.not_to change { Item.find(items(:item1).id).updated_at } }
          end
        end

        context 'with invalid amount function, ' do
          before do
            @old_item1 = old_item1 = items(:item1)
            @action = lambda {
              xhr(:put, :update,
                  id: old_item1.id,
                  entry: {
                    name: 'テスト10',
                    action_date: old_item1.action_date.strftime('%Y/%m/%d'),
                    amount: '(100-20)*(10',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id,
                    confirmation_required: 'true'
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'item to update' do
            def item
              Item.find(@old_item1.id)
            end
            it { expect { @action.call }.not_to change { item.updated_at } }
            it { expect { @action.call }.not_to change { item.name } }
            it { expect { @action.call }.not_to change { item.action_date } }
            it { expect { @action.call }.not_to change { item.amount } }
          end
        end

        context 'with to_account_id which is not owned the user, ' do
          before do
            @old_item1 = old_item1 = items(:item1)
            @action = lambda {
              xhr(:put, :update,
                  id: old_item1.id,
                  entry: {
                    name: 'テスト10',
                    action_date: old_item1.action_date.strftime('%Y/%m/%d'),
                    amount: '1000',
                    from_account_id: accounts(:bank1).id,
                    to_account_id: 43_214,
                    confirmation_required: 'true'
                  },
                  year: 2008,
                  month: 2)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
            it { is_expected.to render_js_error id: "item_warning_#{@old_item1.id}" }
          end

          describe 'item to update' do
            def item
              Item.find(@old_item1.id)
            end
            it { expect { @action.call }.not_to change { item.updated_at } }
            it { expect { @action.call }.not_to change { item.name } }
            it { expect { @action.call }.not_to change { item.action_date } }
            it { expect { @action.call }.not_to change { item.amount } }
          end
        end

        context 'without changing date, ' do
          before do
            @old_item11 = items(:item11)
            xhr(:put, :update,
                id: @old_item11.id,
                entry: {
                  name: 'テスト11',
                  action_date: @old_item11.action_date.strftime('%Y/%m/%d'),
                  amount: '100000',
                  from_account_id: accounts(:bank1).id,
                  to_account_id: accounts(:expense3).id
                },
                year: 2008,
                month: 2)
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            subject { Item.find(@old_item11.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト11' }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @old_item11.action_date }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 100_000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end
          end
        end

        context 'with amount being function,' do
          before do
            @old_item1 = old_item1 = items(:item1)
            @date = old_item1.action_date + 65
            xhr(:put, :update,
                id: items(:item1).id,
                entry: {
                  name: 'テスト10000',
                  action_date: @date.strftime('%Y/%m/%d'),
                  amount: '(100-20)*1.007',
                  from_account_id: accounts(:bank1).id,
                  to_account_id: accounts(:expense3).id,
                  confirmation_required: 'true'
                },
                year: 2008,
                month: 2)
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            subject { Item.find(@old_item1.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト10000' }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @date }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq((80 * 1.007).to_i) }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end
            it { is_expected.to be_confirmation_required }
          end
        end

        describe 'update without change month' do
          let(:old_item1) { items(:item1) }
          context 'when there are adjustment in the same and future month,' do
            let(:old_action_date) { old_item1.action_date }
            before do
              @action = lambda {
                xhr(:put, :update,
                    id: old_item1.id,
                    entry: {
                      name: 'テスト10',
                      action_date: Date.new(old_item1.action_date.year, old_item1.action_date.month, 18).strftime('%Y/%m/%d'),
                      amount: '100000',
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s,
                      confirmation_required: '0'
                    },
                    year: 2008,
                    month: 2)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'updated item' do
              before do
                @action.call
              end
              subject { Item.find(old_item1.id) }

              describe '#name' do
                subject { super().name }
                it { is_expected.to eq 'テスト10' }
              end

              describe '#action_date' do
                subject { super().action_date }
                it { is_expected.to eq Date.new(old_action_date.year, old_action_date.month, 18) }
              end

              describe '#amount' do
                subject { super().amount }
                it { is_expected.to eq 100_000 }
              end

              describe '#from_account_id' do
                subject { super().from_account_id }
                it { is_expected.to eq accounts(:bank1).id }
              end

              describe '#to_account_id' do
                subject { super().to_account_id }
                it { is_expected.to eq accounts(:expense3).id }
              end
              it { is_expected.not_to be_confirmation_required }
            end

            describe 'adjustment which is in the same month' do
              let(:adj_id) { items(:adjustment2).id }
              it { expect { @action.call }.to change { Item.find(adj_id).amount }.by(100_000 - old_item1.amount) }
            end

            describe 'adjustment which is in the next month or after' do
              let(:id4) { items(:adjustment4).id }
              let(:id6) { items(:adjustment6).id }
              it { expect { @action.call }.not_to change { Item.find(id4).amount } }
              it { expect { @action.call }.not_to change { Item.find(id6).amount } }
            end

            describe 'profit losses of the months before the updated item' do
              let(:in200712_id) { monthly_profit_losses(:bank1200712).id }
              let(:in200801_id) { monthly_profit_losses(:bank1200801).id }
              let(:out200712_id) { monthly_profit_losses(:expense3200712).id }
              let(:out200801_id) { monthly_profit_losses(:expense3200801).id }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200712_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200801_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(out200712_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(out200801_id).amount } }
            end

            describe 'profit loss whose account has some adjustments in the same month (> day) as the updated item' do
              let(:in200802_id) { monthly_profit_losses(:bank1200802).id }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200802_id).amount } }
            end

            describe 'profit loss of the future months' do
              context 'when profit loss exists,' do
                let(:in200803_id) { monthly_profit_losses(:bank1200803).id }
                it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200803_id).amount } }
              end

              describe 'when profit loss doesnot exist' do
                before do
                  @action.call
                end

                subject { MonthlyProfitLoss.where(user_id: users(:user1).id, account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
                it { is_expected.to be_nil }
              end
            end
          end

          context 'when confirmation is true in HTML form,' do
            before do
              @action = lambda {
                xhr(:put, :update,
                    id: old_item1.id,
                    entry: {
                      name: 'テスト10',
                      action_date: Date.new(old_item1.action_date.year, old_item1.action_date.month, 18).strftime('%Y/%m/%d'),
                      amount: '100000',
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s,
                      confirmation_required: 'true'
                    },
                    year: 2008,
                    month: 2)
              }
            end

            subject { Item.find_by_id(items(:item1).id) }
            it { is_expected.to be_confirmation_required }
          end

          describe 'when tags are input,' do
            before do
              @action = lambda {
                xhr(:put, :update,
                    id: old_item1.id,
                    entry: {
                      name: 'テスト10',
                      action_date: Date.new(old_item1.action_date.year,
                                            old_item1.action_date.month,
                                            18).strftime('%Y/%m/%d'),
                      amount: '100000',
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s,
                      confirmation_required: 'true',
                      tag_list: 'hoge fuga'
                    },
                    year: 2008,
                    month: 2)
              }
            end

            describe 'tags' do
              before do
                @action.call
              end

              subject { Item.find(old_item1.id) }

              describe '#tag_list' do
                subject { super().tag_list }
                it { is_expected.to eq 'fuga hoge' }
              end
            end
          end
        end

        context "when updated item's action date changed from before-adj2 to after-adj4 but month of action_date doesn't change," do
          let(:date) { items(:adjustment4).action_date + 1 }
          let(:item1_id) { items(:item1).id }
          let(:adj2_id) { items(:adjustment2).id }
          let(:adj4_id) { items(:adjustment4).id }
          let(:adj6_id) { items(:adjustment6).id }

          before do
            @action = lambda {
              xhr(:put, :update,
                  id: items(:item1).id,
                  entry: {
                    name: 'テスト20',
                    action_date: date.strftime('%Y/%m/%d'),
                    amount: '20000',
                    from_account_id: accounts(:bank1).id.to_s,
                    to_account_id: accounts(:expense3).id.to_s
                  },
                  year: items(:item1).action_date.year,
                  month: items(:item1).action_date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'updated item' do
            before { @action.call }
            subject { Item.find(item1_id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト20' }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 20_000 }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq date }
            end
          end

          describe 'adjustment changes' do
            before { @old_item1 = items(:item1) }
            describe 'adj2' do
              before do
                @old_adj2 = items(:adjustment2)
              end
              it { expect { @action.call }.to change { Item.find(adj2_id).amount }.by(-1 * @old_item1.amount) }
            end

            describe 'adj4' do
              before { @old_adj4 = items(:adjustment4) }
              it { expect { @action.call }.not_to change { Item.find(adj4_id).amount } }
            end

            describe 'adj6' do
              before { @old_adj4 = items(:adjustment4) }
              it { expect { @action.call }.to change { Item.find(adj6_id).amount }.by(20_000) }
            end
          end

          describe 'profit losses' do
            before do
              @old_item1 = items(:item1)
              @old_adj2 = items(:adjustment2)
              @old_adj4 = items(:adjustment4)
              @old_adj6 = items(:adjustment4)
              @old_pl200712 = monthly_profit_losses(:bank1200712)
              @old_pl200801 = monthly_profit_losses(:bank1200801)
              @old_pl200802 = monthly_profit_losses(:bank1200802)
              @old_pl200803 = monthly_profit_losses(:bank1200803)
            end

            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@old_pl200712.id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@old_pl200801.id).amount } }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(@old_pl200802.id).amount }.by(-20_000) }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(@old_pl200803.id).amount }.by(20_000) }
          end
        end

        context 'when updated the item whose action date is after adj4 but same month,' do
          before do
            @item5 = items(:item5)
            @adj4 = items(:adjustment4)
            @adj6 = items(:adjustment6)
            @pl200802 = monthly_profit_losses(:bank1200802)
            @pl200803 = monthly_profit_losses(:bank1200803)

            @action = lambda {
              xhr(:put, :update,
                  id: @item5.id,
                  entry: {
                    name: 'テスト50',
                    action_date: @item5.action_date.strftime('%Y/%m/%d'),
                    amount: '20000',
                    from_account_id: @item5.from_account_id.to_s,
                    to_account_id: @item5.to_account_id.to_s
                  },
                  year: '2008',
                  month: '2')
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'updated item' do
            before { @action.call }
            subject { Item.find(@item5.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト50' }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 20_000 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @item5.action_date }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end
          end

          describe 'adjustments' do
            it { expect { @action.call }.not_to change { Item.find(@adj4.id).amount } }
            it { expect { @action.call }.to change { Item.find(@adj6.id).amount }.by(20_000 - @item5.amount) }
          end

          describe 'monthly pls' do
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(@pl200802.id).amount }.by(-20_000 + @item5.amount) }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(@pl200803.id).amount }.by(20_000 - @item5.amount) }
          end
        end

        context 'when updated the item whose action date is before adj6 but same month,' do
          before do
            @item3 = items(:item3)
            @adj4 = Item.find(items(:adjustment4).id)
            @adj6 = Item.find(items(:adjustment6).id)
            @pl200802 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id)
            @pl200803 = MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id)
            @date = @adj6.action_date - 1
            @action = lambda {
              xhr(:put, :update,
                  id: @item3.id,
                  entry: {
                    name: 'テスト30',
                    action_date: @date.strftime('%Y/%m/%d'),
                    amount: '300',
                    from_account_id: accounts(:bank1).id.to_s,
                    to_account_id: accounts(:expense3).id.to_s
                  },
                  year: @item3.action_date.year.to_s,
                  month: @item3.action_date.month.to_s)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'updated item' do
            before { @action.call }
            subject { Item.find(@item3.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト30' }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 300 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @date }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end
          end

          describe 'adjustments' do
            it { expect { @action.call }.to change { Item.find(@adj4.id).amount }.by(-1 * @item3.amount) }
            it { expect { @action.call }.to change { Item.find(@adj6.id).amount }.by(300) }
          end

          describe 'monthly pls' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@pl200802.id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@pl200803.id).amount } }
          end
        end

        context 'when updated the item whose action date changes from before adj4 to before adj6, ' do
          before do
            @item3 = items(:item3)
            @adj4 = items(:adjustment4)
            @adj6 = items(:adjustment6)
            @pl200802 = monthly_profit_losses(:bank1200802)
            @pl200803 = monthly_profit_losses(:bank1200803)

            @date = @adj6.action_date - 1
            @action = lambda {
              xhr(:put, :update,
                  id: @item3.id,
                  entry: {
                    name: 'テスト50',
                    action_date: @date.strftime('%Y/%m/%d'),
                    amount: '300',
                    from_account_id: accounts(:bank1).id.to_s,
                    to_account_id: accounts(:expense3).id.to_s
                  },
                  year: @item3.action_date.year.to_s,
                  month: @item3.action_date.month.to_s)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'updated item' do
            before { @action.call }
            subject { Item.find(@item3.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テスト50' }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 300 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @date }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq accounts(:bank1).id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq accounts(:expense3).id }
            end
          end

          describe 'adjustments' do
            it { expect { @action.call }.to change { Item.find(@adj4.id).amount }.by(-1 * @item3.amount) }
            it { expect { @action.call }.to change { Item.find(@adj6.id).amount }.by(300) }
          end

          describe 'monthly pls' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@pl200802.id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@pl200803.id).amount } }
          end
        end

        context 'when update item from before adj2 to after adj6,' do
          before do
            @item1 = items(:item1)
            @adj2 = items(:adjustment2)
            @adj4 = items(:adjustment4)
            @adj6 = items(:adjustment6)
            @pl200802 = monthly_profit_losses(:bank1200802)
            @pl200803 = monthly_profit_losses(:bank1200803)
            @date = @adj6.action_date + 1
            @action = lambda {
              xhr(:put, :update,
                  id: @item1.id,
                  entry: {
                    name: 'テストXX',
                    action_date: @date.strftime('%Y/%m/%d'),
                    amount: '300',
                    from_account_id: @item1.from_account_id.to_s,
                    to_account_id: @item1.to_account_id.to_s
                  },
                  year: @item1.action_date.year,
                  month: @item1.action_date.month)
            }
          end

          describe 'response' do
            before { @action.call }
            subject { response }
            it { is_expected.to be_success }

            describe '#content_type' do
              subject { super().content_type }
              it { is_expected.to eq 'text/javascript' }
            end
          end

          describe 'updated item' do
            before { @action.call }
            subject { Item.find(@item1.id) }

            describe '#name' do
              subject { super().name }
              it { is_expected.to eq 'テストXX' }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq 300 }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq @date }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq @item1.from_account_id }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq @item1.to_account_id }
            end
          end

          describe 'adjustments' do
            it { expect { @action.call }.to change { Item.find(@adj2.id).amount }.by(-1 * @item1.amount) }
            it { expect { @action.call }.not_to change { Item.find(@adj4.id).amount } }
            it { expect { @action.call }.not_to change { Item.find(@adj6.id).amount } }
          end

          describe 'monthly pls' do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@pl200802.id).amount } }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(@pl200803.id).amount }.by(-300) }
          end
        end

        describe 'updating credit item' do
          context 'with same accounts, same month,' do
            before do
              dummy_login
              xhr(:post, :create,
                  entry: {
                    action_date: '2008/2/10',
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '2')
              init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = init_credit_item.child_item
              date = init_credit_item.action_date

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 4, 20)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              init_payment_item.update_attributes!(action_date: Date.new(2008, 6, 1))

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.id,
                    entry: {
                      name: 'テスト20',
                      action_date: date.strftime('%Y/%m/%d'),
                      amount: '20000',
                      from_account_id: accounts(:credit4).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s
                    },
                    year: init_credit_item.action_date.year,
                    month: init_credit_item.action_date.month)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe 'updated item' do
              it { expect { @action.call }.to change { Item.find(@credit_id).amount }.to(20_000) }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
            end

            describe 'payment item' do
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.amount }.to(20_000) }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.name }.to('テスト20') }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.action_date } }
            end

            describe 'monthly profit losses' do
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).first.amount }.by(-10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 6, 1)).first.amount }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 6, 1)).first.amount }.by(-10_000) }
            end
          end

          context 'with same accounts, changed month,' do
            before do
              dummy_login
              xhr(:post, :create,
                  entry: {
                    action_date: '2008/2/10',
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '2')
              init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = init_credit_item.child_item

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 4, 20)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.id,
                    entry: {
                      name: 'テスト10',
                      action_date: '2008/3/10',
                      amount: '20000',
                      from_account_id: accounts(:credit4).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s
                    },
                    year: init_credit_item.action_date.year,
                    month: init_credit_item.action_date.month)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe 'updated item' do
              it { expect { @action.call }.to change { Item.find(@credit_id).amount }.to(20_000) }
              it { expect { @action.call }.to change { Item.find(@credit_id).action_date }.to(Date.new(2008, 3, 10)) }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.id } }
            end

            describe 'payment item' do
              it { expect { @action.call }.to change { Item.find(Item.find(@credit_id).child_item.id).amount }.to(20_000) }
              it { expect { @action.call }.not_to change { Item.find(Item.find(@credit_id).child_item.id).from_account_id } }
              it { expect { @action.call }.to change { Item.find(Item.find(@credit_id).child_item.id).action_date }.to(Date.new(2008, 5, 20)) }
            end

            describe 'monthly profit losses' do
              describe "credit prev action_date's month" do
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).sum(:amount) }.by(10_000) }
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).sum(:amount) }.by(-10_000) }
              end

              describe "payment prev action_date's month" do
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).sum(:amount) }.by(-10_000) }
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).sum(:amount) }.by(10_000) }
              end
              describe "credit new action_date's month" do
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 3, 1)).sum(:amount) }.by(-20_000) }
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 3, 1)).sum(:amount) }.by(20_000) }
              end

              describe "payment new action_date's month" do
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 5, 1)).sum(:amount) }.by(20_000) }
                it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 5, 1)).sum(:amount) }.by(-20_000) }
              end
            end
          end

          context 'with other accounts, same month,' do
            before do
              dummy_login
              xhr(:post, :create,
                  entry: {
                    action_date: '2008/2/10',
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '2')
              init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = Item.find(init_credit_item.child_item.id)

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 4, 20)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.id,
                    entry: {
                      name: 'テストUpdate10',
                      action_date: '2008/2/10',
                      amount: '20000',
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense13).id.to_s
                    },
                    year: init_credit_item.action_date.year.to_s,
                    month: init_credit_item.action_date.month.to_s)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.to change { Item.count }.by(-1) }
            end

            describe 'updated item' do
              it { expect { @action.call }.to change { Item.find(@credit_id).amount }.to(20_000) }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).action_date } }
              it { expect { @action.call }.to change { Item.find(@credit_id).from_account_id }.to(1) }
              it { expect { @action.call }.to change { Item.find(@credit_id).to_account_id }.to(13) }
            end

            describe 'payment item' do
              it { expect { @action.call }.to change { Item.find_by_id(@payment_id) }.to(nil) }
            end

            describe 'adjustment' do
              it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).amount }.by(20_000) }
            end

            describe 'monthly profit losses' do
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).sum(:amount) }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).sum(:amount) }.by(-10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).sum(:amount) }.by(-10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).sum(:amount) }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 13, month: Date.new(2008, 2, 1)).sum(:amount) }.by(20_000) }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 2, 1)).sum(:amount) } }
            end
          end
        end

        context "when change child_item's action_date," do
          context 'with same month,' do
            before do
              dummy_login
              xhr(:post, :create,
                  entry: {
                    action_date: '2008/2/10',
                    name: 'テスト10', amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '2')
              init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = init_credit_item.child_item

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 4, 20)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.child_item.id,
                    entry: { action_date: Date.new(2008, 4, 21).strftime('%Y/%m/%d') },
                    year: init_credit_item.action_date.year,
                    month: init_credit_item.action_date.month)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe 'updated item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
            end

            describe 'payment item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.name } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.action_date }.by(1) }
            end

            describe 'monthly profit losses' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).first.amount } }
            end
          end

          context 'to next month, which is after adjustment anyway,' do
            before do
              dummy_login
              xhr(:post, :create,
                  entry: {
                    action_date: '2008/1/10',
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '1')
              init_credit_item = Item.where(action_date: Date.new(2008, 1, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = init_credit_item.child_item

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 3, 20)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.child_item.id,
                    entry: { action_date: Date.new(2008, 4, 20).strftime('%Y/%m/%d') },
                    year: init_credit_item.action_date.year,
                    month: init_credit_item.action_date.month)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe 'parent item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).amount } }
            end

            describe 'payment item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.name } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.action_date }.to(Date.new(2008, 4, 20)) }
            end

            describe 'monthly profit losses' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 1, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 1, 1)).sum(:amount) } }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 3, 1)).sum(:amount) }.by(-10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 3, 1)).sum(:amount) }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).sum(:amount) }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).sum(:amount) }.by(-10_000) }
            end
          end

          context 'when change to next month and which changes the order of adjustment,' do
            before do
              dummy_login
              credit_relations(:cr1).update_attributes!(payment_day: 19)
              xhr(:post, :create,
                  entry: {
                    action_date: '2007/12/10',
                    name: 'テスト10',
                    amount: '10,000',
                    from_account_id: accounts(:credit4).id,
                    to_account_id: accounts(:expense3).id
                  },
                  year: '2008',
                  month: '1')
              init_credit_item = Item.where(action_date: Date.new(2007, 12, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              init_payment_item = init_credit_item.child_item

              expect(init_credit_item.amount).to eq 10_000
              expect(init_payment_item.amount).to eq 10_000
              expect(init_payment_item.to_account_id).to eq init_credit_item.from_account_id
              expect(init_payment_item.from_account_id).to eq 1
              expect(init_payment_item.action_date).to eq Date.new(2008, 2, 19)
              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = lambda {
                xhr(:put, :update,
                    id: init_credit_item.child_item.id,
                    entry: { action_date: Date.new(2008, 3, 1).strftime('%Y/%m/%d') },
                    year: init_credit_item.action_date.year,
                    month: init_credit_item.action_date.month)
              }
            end

            describe 'response' do
              before do
                @action.call
              end
              subject { response }
              it { is_expected.to be_success }
            end

            describe 'the number of items' do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe 'parent item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).amount } }
            end

            describe 'payment item' do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.name } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.action_date }.to(Date.new(2008, 3, 1)) }
            end

            describe 'adjustment' do
              it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).amount }.by(-10_000) }
              it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).amount } }
              it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(10_000) }
            end

            describe 'monthly profit losses' do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2007, 12, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2007, 12, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 1, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 1, 1)).sum(:amount) } }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).sum(:amount) }.by(-10_000) }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 2, 1)).sum(:amount) } }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 3, 1)).sum(:amount) }.by(10_000) }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 3, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).sum(:amount) } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).sum(:amount) } }
            end
          end
        end
      end
    end
  end
end
