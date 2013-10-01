# -*- coding: utf-8 -*-
require 'spec_helper'

describe Api::EntriesController do
  fixtures :all

  describe "#index" do
    context "before login," do
      before do
        get :index, format: :json
      end

      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login," do
      let(:mock_user) { users(:user1) }
      before do
        mock_user
        User.should_receive(:find_by_id_and_active).with(mock_user.id, true).at_least(1).and_return(mock_user)
        login
      end

      context "when input values are invalid," do
        before do
          get :index, year: '2008', month: '13', format: :json
        end

        subject { response }
        its(:response_code) { should == 406 }
        its(:body) { should be_blank }
      end

      shared_examples_for "Success in JSON" do
        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end
      end

      shared_examples_for "no params in JSON" do
        it_should_behave_like "Success in JSON"

        describe "@items" do
          subject { assigns(:items) }
          specify {
            subject.each do |item|
              item.action_date.should be_between(Date.today.beginning_of_month, Date.today.end_of_month)
            end
          }
        end
      end

      context "when year and month are not specified," do
        before do
          get :index, format: :json
        end
        it_should_behave_like "no params in JSON"
      end

      context "when year and month are specified," do
        context "when year and month is today's ones," do
          before do
            get :index, year: Date.today.year, month: Date.today.month, format: :json
          end
          it_should_behave_like "no params in JSON"
        end

        context "when year and month is specified but they are not today's ones," do
          before do
            get :index, year: '2008', month: '2', format: :json
          end

          it_should_behave_like "Success in JSON"
          describe "@items" do
            subject { assigns(:items) }
            specify {
              subject.each do |item|
                item.action_date.should be_between(Date.new(2008, 2), Date.new(2008, 2).end_of_month)
              end
            }
          end
        end
      end

      context "with tag," do
        before do
          tags = ['test_tag', 'def']
          put(:update, id: items(:item11).id.to_s,
              entry: { name: 'テスト11',
                action_date: items(:item11).action_date.strftime("%Y/%m/%d"),
                amount: "100000",
                from_account_id: accounts(:bank1).id.to_s,
                to_account_id: accounts(:expense3).id.to_s,
                tag_list: tags.join(" ") },
              format: :json)

          get :index, tag: 'test_tag', format: :json
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "@items" do
          subject { assigns(:items) }
          it { should have(1).items }
        end

        describe "@tag" do
          subject { assigns(:tag) }
          it { should be == 'test_tag' }
        end
      end

      context "with mark," do
        before do
          put(:update, id: items(:item11).id.to_s,
              entry: { item_name: 'テスト11',
                action_date: items(:item11).action_date.strftime("%Y/%m/%d"),
                amount: "100000",
                from_account_id: accounts(:bank1).id.to_s,
                to_account_id: accounts(:expense3).id.to_s,
                confirmation_required: '1' },
              format: :json)
          get :index, mark: 'confirmation_required', format: :json
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "@items" do
          subject { assigns(:items) }
          it { should have(Item.where(confirmation_required: true).count).items }
          specify {
            subject.each do |item|
              item.should be_confirmation_required
            end
          }
        end
      end

      context "with keyword," do
        before do
          put(:update, id: items(:item11).id.to_s,
              entry: { name: 'あああテスト11いいい',
                action_date: items(:item11).action_date.strftime("%Y/%m/%d"),
                amount: "100000",
                from_account_id: accounts(:bank1).id.to_s,
                to_account_id: accounts(:expense3).id.to_s,
                confirmation_required: '1' },
              format: :json)
          get :index, keyword: 'テスト11', format: :json
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "@items" do
          subject { assigns(:items) }
          its(:size) { should == 1 }
        end
      end

      context "with filter change," do
        context "with valid filter_account_id," do
          shared_examples_for "filtered index in JSON" do
            describe "response" do
              subject { response }
              it { should be_success }
              it { should render_template "index" }
            end

            describe "@items" do
              subject { assigns(:items) }
              specify {
                subject.each do |item|
                  [item.from_account_id, item.to_account_id].should include(accounts(:bank1).id)
                end
              }
            end

            describe "session[:filter_account_id]" do
              subject {  session[:filter_account_id] }
              it { should be == accounts(:bank1).id }
            end
          end

          before do
            get :index, filter_account_id: accounts(:bank1).id, year: '2008', month: '2', format: :json
          end

          it_should_behave_like "filtered index in JSON"

          context "after changing filter, access index with no filter_account_id," do
            before do
              get :index, year: '2008', month: '2', format: :json
            end

            it_should_behave_like "filtered index in JSON"
          end

          context "after changing filter, access with filter_account_id nil," do
            before do
              @non_bank1_item = users(:user1).general_items.create!(name: "not bank1 entry", action_date: Date.new(2008, 2, 15), from_account_id: accounts(:income2).id, to_account_id: accounts(:expense3).id, amount: 1000)
            end

            describe "check of setup" do
              describe "previous session" do
                subject { session[:filter_account_id] }
                it { should == accounts(:bank1).id }
              end
            end

            describe "session[:filter_account_id]" do
              before do
                get :index, filter_account_id: "", year: '2008', month: '2', format: :json
              end
              
              subject {  session[:filter_account_id] }
              it { should be_nil }
            end

            describe "@items" do
              before do
                get :index, filter_account_id: "", year: '2008', month: '2', format: :json
              end
              subject { assigns(:items) }
              it { should include(@non_bank1_item) }
            end
          end
        end
      end

      context "with params[:remaining] = true," do
        shared_examples_for "executed correctly in JSON" do
          describe "response" do
            subject { response }
            it { should be_success }
            it { should render_template "index" }
          end
        end

        context "without other params," do
          describe "user.items.partials" do
            it "is called with :remain => true" do
              stub_date_from = Date.new(2008, 2)
              stub_date_to = Date.new(2008, 2).end_of_month
              mock_items = users(:user1).items
              mock_user.should_receive(:items).and_return(mock_items)
              mock_items.should_receive(:partials).with(stub_date_from, stub_date_to,
                                                            hash_including(remain: true)).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).to_a)
              get :index, remaining: 1, year: 2008, month: 2, format: :json
            end
          end

          describe "other than user.items.partials" do
            before do
              mock_items = users(:user1).items
              mock_user.should_receive(:items).and_return(mock_items)
              mock_items.stub(:partials).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).to_a)
              get :index, remaining: true, year: 2008, month: 2, format: :json
            end

            it_should_behave_like "executed correctly in JSON"

            describe "@items" do
              subject { assigns(:items) }
              it { should_not be_empty }
            end
          end
        end

        context "and params[:tag] = 'xxx'," do
          describe "user.items.partials" do
            it "called with tag => 'xxx' and :remain => true" do
              mock_items = users(:user1).items
              mock_user.should_receive(:items).and_return(mock_items)
              mock_items.should_receive(:partials).with(nil, nil,
                                                        hash_including(tag: 'xxx', remain: true)).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).to_a)
              get :index, remaining: true, year: 2008, month: 2, tag: 'xxx', format: :json
            end
          end

          describe "other than user.items.partials," do
            before do
              Item.stub(:partials).and_return(Item.where(action_date: Date.new(2008, 2)..Date.new(2008, 2).end_of_month).to_a)
              get :index, remaining: true, year: 2008, month: 2, tag: 'xxx', format: :json
            end

            it_should_behave_like "executed correctly in JSON"

            describe "@items" do
              subject { assigns(:items) }
              # 0 item for  remaining
              it { should_not be_empty }
            end
          end
        end

        context "and invalid year and month in params," do
          before do
            get :index, remaining: true, year: 2008, month: 15, format: :json
          end
          describe "response" do
            subject { response }
            its(:response_code) { should == 406 }
          end
        end
      end
    end
  end


  describe "#show" do
    context "before login," do
      before do
        get :show, id: items(:item1).id, format: :json
      end
      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login," do
      before do
        login
      end

      context "with valid id," do
        before do
          get :show, id: items(:item1).id, format: :json
        end
        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "show" }
        end

        describe "@item" do
          subject { assigns(:item) }
          it { should_not be_nil }
          it { should be_an_instance_of GeneralItem }
        end
      end

      context "with invalid id," do
        before do
          get :show, id: 341_341, format: :json
        end
        describe "response" do
          subject { response }
          its(:response_code) { should == 404 }
        end
      end
    end
  end

  describe "#destroy" do
    context "before login," do
      before do
        delete :destroy, id: 12_345, format: :json
      end
      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login," do
      let(:mock_user) { users(:user1) }
      before do
        mock_user
        User.should_receive(:find_by_id_and_active).with(mock_user.id, true).at_least(1).and_return(mock_user)
        login
      end

      context "when id in params is invalid," do
        let(:mock_items) { double }
        before do
          mock_user.should_receive(:items).and_return(mock_items)
          mock_items.should_receive(:find).with("12345").and_raise(ActiveRecord::RecordNotFound.new)
          delete :destroy, id: 12_345, format: :json
        end

        describe "response" do
          subject { response }
          its(:response_code) { should == 404 }
        end
      end

      context "item's adjustment is false" do
        context "given there is a future's adjustment," do
          before do
            @old_item1 = items(:item1)
            @old_adj2 = items(:adjustment2)
            @old_bank1pl = monthly_profit_losses(:bank1200802)
            @old_expense3pl = monthly_profit_losses(:expense3200802)

            login

            delete :destroy, id: @old_item1.id, year: @old_item1.action_date.year, month: @old_item1.action_date.month, format: :json
          end

          describe "response" do
            subject { response }
            it { should be_success }
            its(:content_type) { should == "application/json" }
          end

          describe "the specified item" do
            subject { Item.where(id: @old_item1.id).to_a }
            it { should have(0).item }
          end

          describe "the future adjustment item" do
            subject { Item.find(@old_adj2.id) }
            its(:amount) { should == @old_adj2.amount - @old_item1.amount }
          end

          describe "amount of Montly profit loss of from_account" do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }
            its(:amount) { should == @old_bank1pl.amount }
          end

          describe "amount of Montly profit loss of to_account" do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:expense3200802).id) }
            its(:amount) { should == @old_expense3pl.amount - @old_item1.amount }
          end
        end

        context "given there is a future's adjustment whose id is to_account_id," do
          before do
            # prepare data to destroy
            post :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/3', from_account_id: '2', to_account_id: '1' }, year: "2008", month: "2", format: :json
            @item_to_del = Item.where(action_date: Date.new(2008, 2, 3), from_account_id: 2, to_account_id: 1).first
            @previous_amount = @item_to_del.amount

            @old_adj2 = items(:adjustment2)
            @old_bank1 = monthly_profit_losses(:bank1200802)
            @old_income = MonthlyProfitLoss.where(user_id: users(:user1).id, account_id: accounts(:income2).id, month: Date.new(2008, 2)).first

            login
            date = @item_to_del.action_date
            delete :destroy, id: @item_to_del.id, year: date.year.to_s, month: date.month.to_s, day: date.day, format: :json
          end

          describe "previous amount" do
            subject { @previous_amount }
            it { should == 1000 }
          end

          describe "response" do
            subject { response }
            it { should be_success }
            its(:content_type) { should == "application/json" }
          end

          describe "the specified item" do
            subject { Item.where(id: @item_to_del.id).to_a }
            it { should have(0).item }
          end

          describe "the future adjustment item" do
            subject { Item.find(@old_adj2.id) }
            its(:amount) { should == @old_adj2.amount + @item_to_del.amount }
          end

          describe "amount of Montly profit loss of from_account" do

            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }
            its(:amount) { should == @old_bank1.amount }
          end

          describe "amount of Montly profit loss of to_account" do
            subject { MonthlyProfitLoss.find(@old_income.id) }
            its(:amount) { should == @old_income.amount + @item_to_del.amount }
          end
        end

        context "given there is no future's adjustment," do
          before do
            login
            post :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/25', from_account_id: '11', to_account_id: '13' }, year: 2008, month: 2, format: :json
            @item = Item.where(name: 'test', from_account_id: 11, to_account_id: 13).first
            @old_bank11pl = MonthlyProfitLoss.where(account_id: 11, month: Date.new(2008, 2)).first
            @old_expense13pl = MonthlyProfitLoss.where(account_id: 13, month: Date.new(2008, 2)).first

            delete :destroy, id: @item.id, year: 2008, month: 2, format: :json
          end

          describe "response" do
            subject { response }
            it { should be_success }
          end

          describe "amount of from_account" do
            subject { MonthlyProfitLoss.find(@old_bank11pl.id) }
            its(:amount) { should == @old_bank11pl.amount + @item.amount }
          end

          describe "specified item" do

            it "should does not exist" do
              expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end

          describe "amount of to_account" do
            subject { MonthlyProfitLoss.find(@old_expense13pl.id) }
            its(:amount) { should ==  @old_expense13pl.amount - @item.amount }
          end
        end

        context "when destroy the item which is assigned to credit card account," do
          context "and payment date is in 2 months," do
            let(:action) { lambda { delete :destroy, id: @item.id, year: 2008, month: 2, format: :json } }
            before do
              login
              # dummy data
              post :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/10', from_account_id: '4', to_account_id: '3' }, year: 2008, month: 2, format: :json
              @item = Item.where(name: 'test', from_account_id: 4, to_account_id: 3).first
              @child_item = @item.child_item
            end

            describe "response" do
              before { action.call }
              subject { response }
              it { should be_success }
            end

            describe "specified item" do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe "child item of the specified item" do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@child_item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe "profit_losses" do
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2)).sum(:amount) }.by(1000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2)).sum(:amount) }.by(-1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4)).sum(:amount) }.by(1000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4)).sum(:amount) }.by(-1_000) }
            end
          end

          context "and payment date is in same months," do
            let(:action) { lambda { delete :destroy, id: @item.id, year: 2008, month: 2, format: :json} }
            before do
              cr = credit_relations(:cr1)
              cr.update_attributes!(payment_month: 0, payment_day: 25, settlement_day: 11)

              login
              # dummy data
              post :create, entry: { name: 'test', amount: '1000', action_date: '2008/2/10', from_account_id: '4', to_account_id: '3' }, year: 2008, month: 2, format: :json
              @item = Item.where(name: 'test', from_account_id: 4, to_account_id: 3).first
              @child_item = @item.child_item
            end

            describe "response" do
              before { action.call }
              subject { response }
              it { should be_success }
              its(:content_type) { should == 'application/json' }
            end

            describe "specified item" do
              before { action.call }
              it 'should not exist' do
                expect { Item.find(@item.id) }.to raise_error(ActiveRecord::RecordNotFound)
              end
            end

            describe "future adjustment" do
              it { expect { action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(-1_000) }
            end

            describe "profit_losses" do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2)).sum(:amount) } }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2)).sum(:amount) }.by(-1_000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 2)).sum(:amount) }.by(1000) }
              it { expect { action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 3)).sum(:amount) }.by(-1_000) }
            end
          end
        end
      end

      context "when adjustment is true," do
        context "with invalid id," do
          let(:mock_items) { double }
          before do
            mock_user.should_receive(:items).and_return(mock_items)
            mock_items.should_receive(:find).with("20000").and_raise(ActiveRecord::RecordNotFound.new)
            delete :destroy, id: 20_000, year: Date.today.year, month: Date.today.month, format: :json
          end
          subject { response }
          its(:response_code) { should == 404 }
        end

        context "with correct id," do
          context "when change adj2's amount" do
            before do
              login

              @init_adj2 = Item.find(items(:adjustment2).id)
              @init_adj4 = Item.find(items(:adjustment4).id)
              @init_adj6 = Item.find(items(:adjustment6).id)
              @init_bank_pl = monthly_profit_losses(:bank1200802)
              @init_bank_pl = monthly_profit_losses(:bank1200802)
              @init_unknown_pl = MonthlyProfitLoss.where(month: Date.new(2008, 2), account_id: -1, user_id: users(:user1).id).first

              @action = lambda { delete :destroy, id: items(:adjustment2).id, year: 2008, month: 2, format: :json }
            end

            describe "response" do
              before { @action.call }
              subject { response }
              it { should be_success }
              its(:response_code) { should == 200 }
            end

            describe "specified item(adjustment2)" do
              before { @action.call }
              subject { Item.find_by_id(@init_adj2.id) }
              it { should be_nil }
            end

            describe "adjustment4 which is next future adjustment" do
              it { expect { @action.call }.to change { Item.find(@init_adj4.id).amount }.by(@init_adj2.amount) }
            end

            describe "bank_pl amount" do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@init_bank_pl.id).amount } }
            end

            describe "unknown pl amount" do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(@init_unknown_pl.id).amount } }
            end
          end
        end
      end
    end
  end

  describe "#create" do
    context "before login," do
      before do
        post :create, format: :json
      end
      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login, " do
      before do
        login
      end

      shared_examples_for "not acceptable" do
        describe "response_code" do
          subject { response.response_code }
          it { should == 406 }
        end

        describe "response body" do
          subject { ActiveSupport::JSON.decode(response.body)["errors"] }
          it { should have_at_least(1).errors }
        end
      end

      context "when validation errors happen," do
        before do
          @previous_items = Item.count
          post :create, entry: { action_date: Date.today.strftime("%Y/%m/%d"),  name: '', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month, format: :json
        end

        it_should_behave_like "not acceptable"

        describe "the count of items" do
          subject { Item.count }
          it { should == @previous_items }
        end
      end

      context "when input action_year, action_month, action_day is specified but action_date is not," do
        before do
          @previous_items = Item.count
          post :create, entry: { action_year: Date.today.year.to_s, action_month: Date.today.month.to_s, action_day: Date.today.day.to_s,  name: 'TEST11', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month, format: :json
        end

        it_should_behave_like "not acceptable"

        describe "the count of items" do
          subject { Item.count }
          it { should == @previous_items }
        end
      end

      shared_examples_for "created successfully by JSON" do
        describe "response" do
          subject { response }
          it { should be_success }
          its(:response_code) { should == 201 }
        end
      end

      context "when input amount's syntax is incorrect," do
        before do
          @previous_item_count = Item.count
          post :create, entry: { action_date: Date.today.strftime("%Y/%m/%d"), name: 'hogehoge', amount: '1+x', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id }, year: Date.today.year, month: Date.today.month, format: :json
        end
        it_should_behave_like "not acceptable"
      end

      shared_examples_for "created successfully with tag_list == 'hoge fuga by JSON" do
        describe "tags" do
          describe "tag size" do
            subject { Tag.where(name: 'hoge').to_a }
            it { should have(1).tag }
          end
          describe "taggings" do
            let(:tag_ids) { Tag.where(name: 'hoge').pluck(:id) }

            describe "taggings' size" do
              subject { Tagging.where(tag_id: tag_ids).to_a }
              it { should have(1).tagging }
            end

            describe "taggings' user_id" do
              subject {
                uids = Tagging.where(tag_id: tag_ids).pluck(:user_id)
                uids.all? { |u| u == users(:user1).id }
              }
              it { should be_true }
            end

            describe "taggings' taggable_type" do
              subject {
                types = Tagging.where(tag_id: tag_ids).pluck(:taggable_type)
                types.all? { |t| t == 'Item' }
              }
              it { should be_true }
            end
          end
        end
      end

      context "with confirmation_required == true" do
        before do
          @init_item_count = Item.count
          post :create, entry: { action_date: Date.today.strftime("%Y/%m/%d"), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: 'true', tag_list: 'hoge fuga' }, year: Date.today.year.to_s, month: Date.today.month.to_s, format: :json
        end

        it_should_behave_like "created successfully by JSON"

        describe "count of items" do
          subject { Item.count }
          it { should == @init_item_count + 1 }
        end

        describe "created item" do
          subject {
            id = Item.maximum('id')
            Item.find_by_id(id)
          }

          its(:name) { should == 'テスト10' }
          its(:amount) { should == 10_000 }
          it { should be_confirmation_required }
          its(:tag_list) { should == "fuga hoge" }
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga by JSON"
      end

      context "with confirmation_required == nil" do
        before do
          @init_item_count = Item.count
          post :create, entry: { action_date: Date.today.strftime("%Y/%m/%d"), name: 'テスト10', amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga' }, year: Date.today.year.to_s, month: Date.today.month.to_s, format: :json
        end

        it_should_behave_like "created successfully by JSON"

        describe "count of items" do
          subject { Item.count }
          it { should == @init_item_count + 1 }
        end

        describe "created item" do
          subject {
            id = Item.maximum('id')
            Item.find_by_id(id)
          }

          its(:name) { should == 'テスト10' }
          its(:amount) { should == 10_000 }
          it { should_not be_confirmation_required }
          its(:tag_list) { should == "fuga hoge" }
        end

        it_should_behave_like "created successfully with tag_list == 'hoge fuga by JSON"
      end

      context "when amount needs to be calcurated, but syntax error exists," do
        before do
          @init_item_count = Item.count
          post :create, entry: { action_date: Date.today.strftime("%Y/%m/%d"), name: 'テスト10', amount: '(10+20*2.01', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, confirmation_required: '' }, year: Date.today.year, month: Date.today.month, format: :json
        end

        describe "response" do
          subject { response }
          its(:response_code) { should == 406 }
        end

        describe "response_body" do
          subject { ActiveSupport::JSON.decode(response.body)["errors"] }
          it { should have_at_least(1).errors }
        end

        describe "count of items" do
          subject { Item.count }
          it { should == @init_item_count }
        end
      end

      context "with correct params," do
        before do
          @init_adj2 = Item.find(items(:adjustment2).id)
          @init_adj4 = Item.find(items(:adjustment4).id)
          @init_adj6 = Item.find(items(:adjustment6).id)
          @init_pl0712 = monthly_profit_losses(:bank1200712)
          @init_pl0801 = monthly_profit_losses(:bank1200801)
          @init_pl0802 = monthly_profit_losses(:bank1200802)
          @init_pl0803 = monthly_profit_losses(:bank1200803)
          login
        end

        context "created before adjustment which is in the same month," do
          before do
            post(:create,
                 entry: { action_date: @init_adj2.action_date.yesterday.strftime("%Y/%m/%d"),
                   name: 'テスト10', amount: '10,000',
                   from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id },
                 year: 2008, month: 2, format: :json)
          end

          it_should_behave_like "created successfully by JSON"

          describe "adjustment just next to the created item" do
            subject { Item.find(items(:adjustment2).id) }
            its(:amount) { should == @init_adj2.amount + 10_000 }
          end

          describe "adjustment which is the next of the adjustment next to the created item" do
            subject { Item.find(items(:adjustment4).id) }
            its(:amount) { should == @init_adj4.amount }
          end

          describe "adjustment which is the second next of the adjustment next to the created item" do
            subject { Item.find(items(:adjustment6).id) }
            its(:amount) { should == @init_adj6.amount }
          end

          describe "monthly pl which is before the created item" do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id) }
            its(:amount) { should == @init_pl0801.amount }
          end

          describe "monthly pl of the same month of the created item" do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) }
            its(:amount) { should == @init_pl0802.amount }
          end

          describe "monthly pl of the next month of the created item" do
            subject { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id) }
            its(:amount) { should == @init_pl0803.amount }
          end
        end
      end

      describe "credit card payment" do
        context "created item with credit card, purchased before the settlement date of the month" do
          before do
            login
            post(:create,
                 entry: { action_date: '2008/02/10',
                   name: 'テスト10', amount: '10,000',
                   from_account_id: accounts(:credit4).id, to_account_id: accounts(:expense3).id },
                 year: 2008, month: 2, format: :json)
          end

          let(:credit_item) {
            Item.where(action_date: Date.new(2008, 2, 10),
                       from_account_id: accounts(:credit4).id,
                       to_account_id: accounts(:expense3).id,
                       amount: 10_000,
                       parent_id: nil).find { |i| i.child_item }
          }

          describe "response" do
            subject { response }
            it { should be_success }
            its(:content_type) { should == "application/json" }
          end

          describe "created credit item" do
            subject { credit_item }
            it { should_not be_nil }
            its(:amount) { should == 10_000 }
            its(:parent_id) { should be_nil }
            its(:child_item) { should_not be_nil }
          end

          describe "child item's count" do
            subject { Item.where(parent_id: credit_item.id) }
            its(:count) { should == 1 }
          end

          describe "child item" do
            subject { Item.where(parent_id: credit_item.id).find { |i| i.child_item.nil? } }
            its(:child_item) { should be_nil }
            its(:parent_item) { should == credit_item }
            its(:action_date) { should == Date.new(2008, 2 + credit_relations(:cr1).payment_month, credit_relations(:cr1).payment_day) }
            its(:from_account_id) { should == credit_relations(:cr1).payment_account_id }
            its(:to_account_id) { should == credit_relations(:cr1).credit_account_id }
            its(:amount) { should == 10_000 }
          end
        end
      end

      describe "balance adjustment" do
        context "action_year/month/day is set," do
          it { expect { post :create, entry: { action_year: '2008', action_month: '2', action_day: '5', from_account_id: '-1', to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000', entry_type: 'adjustment' }, year: 2008, month: 2, format: :json }.not_to change { Item.count } }
        end

        context "when a validation error occurs," do
          before do
            mock_exception = ActiveRecord::RecordInvalid.new(stub_model(Item))
            mock_exception.should_receive(:error_messages).and_return("Error!!!")
            Teller.should_receive(:create_entry).and_raise(mock_exception)
            @action = lambda {
              post :create, entry: { action_date: '2008/02/05',
                from_account_id: '-1', to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000', entry_type: 'adjustment' }, year: 2008, month: 2, format: :json
            }
          end

          describe "response" do
            before { @action.call }
            subject { response }
            its(:response_code) { should == 406 }
            its(:content_type) { should == 'application/json' }
          end

          describe "response body" do
            before { @action.call }
            subject { ActiveSupport::JSON.decode(response.body)["errors"] }
            it { should have_at_least(1).errors }
          end
        end

        context "with invalid calcuration amount," do
          let(:date) { items(:adjustment2).action_date - 1 }
          it { expect { post :create, entry: { entry_type: 'adjustment', action_date: date.strftime("%Y/%m/%d"), to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '3000-(10' }, year: 2008, month: 2, format: :json}.not_to change { Item.count } }
        end

        context "add adjustment before any of the adjustments," do
          before do
            login
            @date = items(:adjustment2).action_date - 1
            @action = lambda {
              post(:create, entry: { entry_type: 'adjustment',
                  action_date: @date.strftime("%Y/%m/%d"),
                  to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '100*(10+50)/2', tag_list: 'hoge fuga' }, year: "2008", month: "3", format: :json)
            }
          end

          describe "count of Item" do
            it { expect { @action.call }.to change { Item.count }.by(1) }
          end

          describe "created adjustment" do
            before do
              account_id = accounts(:bank1).id
              init_items = Item.where("action_date <= ?", @date )
              @init_total = init_items.where(to_account_id: account_id).sum(:amount) - init_items.where(from_account_id: account_id).sum(:amount)
              @action.call
              @created_item = Item.where(user_id: users(:user1).id, action_date: @date).order("id desc").first
              prev_items = Item.where("id < ?", @created_item.id).where("action_date <= ?", @date )
              @prev_total = prev_items.where(to_account_id: account_id).sum(:amount) - prev_items.where(from_account_id: account_id).sum(:amount)
            end
            subject { @created_item }

            it { should be_adjustment }
            its(:adjustment_amount) { should == 100 * (10 + 50) / 2 }
            its(:amount) { should == 100 * (10 + 50) / 2 - @prev_total }
            its(:amount) { should == 100 * (10 + 50) / 2 - @init_total }
            its(:tag_list) { should == "fuga hoge" }
          end

          describe "profit losses" do
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200712).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
          end

          describe "tag" do
            it { expect { @action.call }.to change { Tag.where(name: 'hoge').count }.by(1) }
            it { expect { @action.call }.to change { Tag.where(name: 'fuga').count }.by(1) }
          end

          describe "taggings" do
            it { expect { @action.call }.to change { Tagging.where(user_id: users(:user1).id, taggable_type: 'Item').count }.by(2) }
          end
        end


        context "create adjustment to the same day as another ajustment's one," do
          context "input values are valid," do

            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) {
              lambda {
                date = existing_adj.action_date
                post(
                    :create, entry: { entry_type: 'adjustment',
                       action_date: date.strftime("%Y/%m/%d"),
                       to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '50' },
                    year: 2008, month: 2, format: :json)
              }
            }
            describe "created_adjustment" do
              before { action.call }
              subject { Adjustment.where(action_date: existing_adj.action_date).first }
              its(:adjustment_amount) { should == 50 }
              its(:amount) { should == existing_adj.amount + 50 - existing_adj.adjustment_amount }
            end

            describe "existed adjustment" do
              before { action.call }
              subject { Item.find_by_id(existing_adj.id) }
              it { should be_nil }
            end

            describe "future adjustment" do
              it { expect { action.call }.to change { Item.find(future_adj.id).amount }.by(existing_adj.adjustment_amount - 50) }
            end

            describe "monthly_pl" do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end

          context "input values are invalid," do
            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) {
              lambda {
                date = existing_adj.action_date
                post(
                    :create, entry: { entry_type: 'adjustment',
                       action_date: date.strftime("%Y/%m/%d"),
                       to_account_id: accounts(:bank1).id.to_s, adjustment_amount: 'SDSFSAF * xdfa' },
                    year: 2008, month: 2, format: :json)
              }
            }

            describe "response" do
              before { action.call }
              subject { response }
              its(:response_code) { should == 406 }
            end

            describe "all adjustments count" do
              it { expect { action.call }.not_to change { Adjustment.count } }
            end
            describe "all item count" do
              it { expect { action.call }.not_to change { Item.count } }
            end

            describe "existing_adj" do
              it { expect { action.call }.not_to change { Item.find(existing_adj.id).amount } }
            end

            describe "future adjustment" do
              it { expect { action.call }.not_to change { Item.find(future_adj.id).amount } }
            end

            describe "profit_losses" do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end

          context "input action_year/month/day is specified," do
            let(:existing_adj) { items(:adjustment2) }
            let(:future_adj) { items(:adjustment4) }
            let(:action) {
              lambda {
                date = existing_adj.action_date
                post(
                    :create, entry: { entry_type: 'adjustment',
                       action_year: date.year, action_month: date.month, action_day: date.day,
                       to_account_id: accounts(:bank1).id.to_s, adjustment_amount: '50000' },
                    year: 2008, month: 2, format: :json)
              }
            }

            describe "response" do
              before { action.call }
              subject { response }
              its(:response_code) { should == 406 }
            end

            describe "response body" do
              before { action.call }
              subject { ActiveSupport::JSON.decode(response.body)["errors"] }
              it { should have_at_least(1).errors }
            end

            describe "all adjustments count" do
              it { expect { action.call }.not_to change { Adjustment.count } }
            end
            describe "all item count" do
              it { expect { action.call }.not_to change { Item.count } }
            end

            describe "existing_adj" do
              it { expect { action.call }.not_to change { Item.find(existing_adj.id).amount } }
            end

            describe "future adjustment" do
              it { expect { action.call }.not_to change { Item.find(future_adj.id).amount } }
            end

            describe "profit_losses" do
              it { expect { action.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
            end
          end
        end
      end
    end
  end

  describe "#update" do
    context "before login," do
      before do
        put :update, entry: { entry_type: 'adjustment', adjustment_amount: "200", to_account_id: "1" }, year: Date.today.year, month: Date.today.month, id: items(:adjustment2).id.to_s, format: :json
      end

      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login," do
      shared_examples_for "fail to update" do
        describe "response" do
          before do
            @action.call
          end

          subject { response }
          its(:response_code) { should == 406 }
        end

        describe "response body" do
          before { @action.call }
          subject { ActiveSupport::JSON.decode(response.body)["errors"] }
          it { should have_at_least(1).errors }
        end
      end

      before do
        login
      end

      describe "update adjustment" do
        context "without params[:entry][:to_account_id]" do
          before do
            @init_adj_amount = items(:adjustment2).adjustment_amount
            date = items(:adjustment2).action_date
            @action = -> {
              put(:update, id: items(:adjustment2).id.to_s,
                  entry: { entry_type: 'adjustment',
                    action_date: date.strftime("%Y/%m/%d"),
                    adjustment_amount: '3,000' },
                  format: :json)
            }
          end

          describe "response" do
            before do
              @action.call
            end

            subject { response }
            its(:response_code) { should == 200 }
          end

          describe "item to update" do
            it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).updated_at } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).to_account_id } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).adjustment_amount }.to(3000) }
            it { expect { @action.call }.to change { Item.find(items(:adjustment2).id).amount }.by(3000 - @init_adj_amount) }
          end
        end

        context "with invalid function for amount" do
          before do
            login
            date = items(:adjustment2).action_date
            @action = -> {
              put(:update, id: items(:adjustment2).id,
                  entry: { entry_type: 'adjustment', action_date: date.strftime("%Y/%m/%d"),
                    adjustment_amount: '(20*30)/(10+1', to_account_id: items(:adjustment2).to_account_id },
                  format: :json)
            }
          end

          it_should_behave_like "fail to update"

          describe "count of items" do
            it { expect { @action.call }.not_to change { Item.count } }
          end
        end

        context "when change amount the adjustment which has an adjustment in the next month" do
          before do
            @old_adj4 = items(:adjustment4)
            date = @old_adj4.action_date
            # 金額のみ変更
            @action = -> {
              put(:update,
                  id: @old_adj4.id,
                  entry: { entry_type: 'adjustment',
                    action_date: date.strftime("%Y/%m/%d"),
                    adjustment_amount: '3,000',
                    to_account_id: @old_adj4.to_account_id } ,
                  format: :json)
            }
          end

          describe "response" do
            before { @action.call }
            subject { response }
            it { should be_success }
          end

          describe "updated item" do
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).updated_at } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).action_date } }
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment4).id).adjustment? } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).adjustment_amount }.to(3000) }
            it { expect { @action.call }.to change { Item.find(items(:adjustment4).id).amount }.by(3000 - @old_adj4.adjustment_amount) }
          end

          describe "other adjustments" do
            it { expect { @action.call }.not_to change { Item.find(items(:adjustment2).id).amount } }
            it { expect { @action.call }.to change { Item.find(items(:adjustment6).id).amount }.by(@old_adj4.adjustment_amount - 3000) }
          end

          describe "monthly pl" do
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount }.by(3000 - @old_adj4.adjustment_amount) }
            it { expect { @action.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(@old_adj4.adjustment_amount - 3000) }
          end
        end
      end

      describe "update item" do
        context "with invalid amount function, " do
          before do
            @old_item1 = old_item1 = items(:item1)
            @action = -> {
              put(:update,
                  id: old_item1.id,
                  entry: {
                    name: 'テスト10',
                    action_date: old_item1.action_date.strftime("%Y/%m/%d"),
                    amount: "(100-20)*(10",
                    from_account_id: accounts(:bank1).id,
                    to_account_id: accounts(:expense3).id,
                    confirmation_required: 'true'
                  }, format: :json)
            }
          end

          it_should_behave_like "fail to update"

          describe "item to update" do
            def item
              Item.find(@old_item1.id)
            end
            it { expect { @action.call }.not_to change { item.updated_at } }
            it { expect { @action.call }.not_to change { item.name } }
            it { expect { @action.call }.not_to change { item.action_date } }
            it { expect { @action.call }.not_to change { item.amount } }
          end
        end

        context "with to_account_id which is not owned the user, " do
          before do
            @old_item1 = old_item1 = items(:item1)
            @action = -> {
              put(:update,
                  id: old_item1.id,
                  entry: {
                    name: 'テスト10',
                    action_date: old_item1.action_date.strftime("%Y/%m/%d"),
                    amount: "1000",
                    from_account_id: accounts(:bank1).id,
                    to_account_id: 43_214,
                    confirmation_required: 'true'
                  }, format: :json)
            }
          end

          it_should_behave_like "fail to update"

          describe "item to update" do
            def item
              Item.find(@old_item1.id)
            end
            it { expect { @action.call }.not_to change { item.updated_at } }
            it { expect { @action.call }.not_to change { item.name } }
            it { expect { @action.call }.not_to change { item.action_date } }
            it { expect { @action.call }.not_to change { item.amount } }
          end
        end

        context "without changing date, " do
          before do
            @old_item11 = items(:item11)
            put(:update, id: @old_item11.id,
                entry: { name: 'テスト11',
                  action_date: @old_item11.action_date.strftime("%Y/%m/%d"),
                  amount: "100000",
                  from_account_id: accounts(:bank1).id,
                  to_account_id: accounts(:expense3).id },
                format: :json)
          end

          describe "response" do
            subject { response }
            it { should be_success }
            its(:response_code) { should == 200 }
          end

          describe "updated item" do
            subject { Item.find(@old_item11.id) }
            its(:name) { should == 'テスト11' }
            its(:action_date) { should == @old_item11.action_date }
            its(:amount) { should == 100_000 }
            its(:from_account_id) { should == accounts(:bank1).id }
            its(:to_account_id) { should == accounts(:expense3).id }
          end
        end

        context "with amount being function," do
          before do
            @old_item1 = old_item1 = items(:item1)
            @date = old_item1.action_date + 65
            put(:update,
                id: items(:item1).id,
                entry: {
                  name: 'テスト10000',
                  action_date: @date.strftime("%Y/%m/%d"),
                  amount: "(100-20)*1.007",
                  from_account_id: accounts(:bank1).id,
                  to_account_id: accounts(:expense3).id,
                  confirmation_required: 'true' },
                format: :json)
          end

          describe "response" do
            subject { response }
            it { should be_success }
            its(:response_code) { should == 200 }
          end

          describe "updated item" do
            subject { Item.find(@old_item1.id) }
            its(:name) { should == 'テスト10000' }
            its(:action_date) { should == @date }
            its(:amount) { should == (80 * 1.007).to_i }
            its(:from_account_id) { should == accounts(:bank1).id }
            its(:to_account_id) { should == accounts(:expense3).id }
            it { should be_confirmation_required }
          end
        end

        describe "update without change month" do
          let(:old_item1) { items(:item1) }
          context "when there are adjustment in the same and future month," do
            let(:old_action_date) { old_item1.action_date }
            before do
              @action = -> {
                put(:update, id: old_item1.id,
                    entry: { name: 'テスト10',
                      action_date: Date.new(old_item1.action_date.year, old_item1.action_date.month, 18).strftime("%Y/%m/%d"),
                      amount: "100000",
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s,
                      confirmation_required: "false"
                    },
                    format: :json)
              }
            end

            describe "response" do
              before do
                @action.call
              end
              subject { response }
              it { should be_success }
            its(:response_code) { should == 200 }
            end

            describe "updated item" do
              before do
                @action.call
              end
              subject { Item.find(old_item1.id) }
              its(:name) { should == 'テスト10' }
              its(:action_date) { should == Date.new(old_action_date.year, old_action_date.month, 18) }
              its(:amount) { should == 100_000 }
              its(:from_account_id) { should == accounts(:bank1).id }
              its(:to_account_id) { should == accounts(:expense3).id }
              it { should_not be_confirmation_required }
            end

            describe "adjustment which is in the same month" do
              let(:adj_id) { items(:adjustment2).id }
              it { expect { @action.call }.to change { Item.find(adj_id).amount }.by(100_000 - old_item1.amount) }
            end

            describe "adjustment which is in the next month or after" do
              let(:id4) { items(:adjustment4).id }
              let(:id6) { items(:adjustment6).id }
              it { expect { @action.call }.not_to change { Item.find(id4).amount } }
              it { expect { @action.call }.not_to change { Item.find(id6).amount } }
            end

            describe "profit losses of the months before the updated item" do
              let(:in200712_id) { monthly_profit_losses(:bank1200712).id }
              let(:in200801_id) { monthly_profit_losses(:bank1200801).id }
              let(:out200712_id) { monthly_profit_losses(:expense3200712).id }
              let(:out200801_id) { monthly_profit_losses(:expense3200801).id }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200712_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200801_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(out200712_id).amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(out200801_id).amount } }
            end

            describe "profit loss whose account has some adjustments in the same month (> day) as the updated item" do
              let(:in200802_id) { monthly_profit_losses(:bank1200802).id }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200802_id).amount } }
            end

            describe "profit loss of the future months" do
              context "when profit loss exists," do
                let(:in200803_id) { monthly_profit_losses(:bank1200803).id }
                it { expect { @action.call }.not_to change { MonthlyProfitLoss.find(in200803_id).amount } }
              end

              describe "when profit loss doesnot exist" do
                before do
                  @action.call
                end

                subject { MonthlyProfitLoss.where(user_id: users(:user1).id, account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
                it { should be_nil }
              end
            end
          end

          describe "when tags are input," do
            before do
              @action = -> {
                put(:update, id: old_item1.id,
                    entry: { name: 'テスト10',
                      action_date: Date.new(old_item1.action_date.year, old_item1.action_date.month, 18).strftime("%Y/%m/%d"),
                      amount: "100000",
                      from_account_id: accounts(:bank1).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s,
                      confirmation_required: 'true', tag_list: 'hoge fuga' },
                    format: :json)
              }
            end

            describe "tags" do
              before do
                @action.call
              end

              subject { Item.find(old_item1.id) }
              its(:tag_list) { should == 'fuga hoge' }
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
              put(:update, id: items(:item1).id,
                  entry: { name: 'テスト20',
                    action_date: date.strftime("%Y/%m/%d"),
                    amount: "20000",
                    from_account_id: accounts(:bank1).id.to_s,
                    to_account_id: accounts(:expense3).id.to_s },
                  format: :json)
            }
          end

          describe "response" do
            before { @action.call }
            subject { response }
            it { should be_success }
            its(:response_code) { should == 200 }
          end

          describe "updated item" do
            before { @action.call }
            subject { Item.find(item1_id) }
            its(:name) { should == "テスト20" }
            its(:amount) { should == 20_000 }
            its(:from_account_id) { should == accounts(:bank1).id }
            its(:to_account_id) { should == accounts(:expense3).id }
            its(:action_date) { should == date }
          end

          describe "adjustment changes" do
            before { @old_item1 = items(:item1) }
            describe "adj2" do
              before do
                @old_adj2 = items(:adjustment2)
              end
              it { expect { @action.call }.to change { Item.find(adj2_id).amount }.by( -1 *  @old_item1.amount) }
            end

            describe "adj4" do
              before { @old_adj4 = items(:adjustment4) }
              it { expect { @action.call }.not_to change { Item.find(adj4_id).amount } }
            end

            describe "adj6" do
              before { @old_adj4 = items(:adjustment4) }
              it { expect { @action.call }.to change { Item.find(adj6_id).amount }.by(20_000) }
            end
          end

          describe "profit losses" do
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

        describe "updating credit item" do
          context "with same accounts, same month," do
            before do
              login
              post(:create,
                   entry: { action_date: '2008/2/10',
                     name: 'テスト10', amount: '10,000', from_account_id: accounts(:credit4).id,
                     to_account_id: accounts(:expense3).id }, year: '2008', month: '2', format: :json)
              @init_credit_item = init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                            from_account_id: accounts(:credit4).id,
                                            to_account_id: accounts(:expense3).id).first

              @init_payment_item = init_payment_item = init_credit_item.child_item
              date = init_credit_item.action_date

              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              init_payment_item.update_attributes!(action_date: Date.new(2008, 6, 1))

              @action = -> {
                put(:update, id: init_credit_item.id,
                    entry: { name: 'テスト20',
                      action_date: date.strftime("%Y/%m/%d"),
                      amount: "20000",
                      from_account_id: accounts(:credit4).id.to_s,
                      to_account_id: accounts(:expense3).id.to_s },
                    format: :json)
              }
            end

            describe "previous state" do
              describe "initial credit item" do
                subject { @init_credit_item }
                its(:amount) { should be == 10_000 }
              end
              
              describe "initial payment item" do
                subject { @init_payment_item }
                its(:amount) { should be == 10_000 }
                its(:to_account_id) { should be == @init_credit_item.from_account_id }
                its(:from_account_id) { should be == 1 }
                its(:action_date) { should be == Date.new(2008, 6, 1) }
              end
            end

            describe "response" do
              before do
                @action.call
              end
              subject { response }
              it { should be_success }
              its(:response_code) { should == 200 }
            end

            describe "the number of items" do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe "updated item" do
              it { expect { @action.call }.to change { Item.find(@credit_id).amount }.to(20_000) }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
            end

            describe "payment item" do
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.amount }.to(20_000) }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.name }.to('テスト20') }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.action_date } }
            end

            describe "monthly profit losses" do
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).first.amount }.by(-10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 6, 1)).first.amount }.by(10_000) }
              it { expect { @action.call }.to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 6, 1)).first.amount }.by(-10_000) }
            end
          end
        end

        context "when change child_item's action_date," do
          context "with same month," do
            before do
              login
              post(:create,
                   entry: { action_date: '2008/2/10',
                     name: 'テスト10', amount: '10,000', from_account_id: accounts(:credit4).id,
                     to_account_id: accounts(:expense3).id }, year: '2008', month: '2', format: :json)
              @init_credit_item = init_credit_item = Item.where(action_date: Date.new(2008, 2, 10),
                                                                from_account_id: accounts(:credit4).id,
                                                                to_account_id: accounts(:expense3).id).first

              @init_payment_item = init_payment_item = init_credit_item.child_item

              @credit_id = init_credit_item.id
              @payment_id = init_payment_item.id

              @action = -> {
                put(:update, id: init_credit_item.child_item.id,
                    entry: { action_date: Date.new(2008, 4, 21).strftime("%Y/%m/%d") },
                    format: :json)
              }
            end

            describe "previous states" do
              describe "initial credit item" do
                subject { @init_credit_item }
                its(:amount) { should be == 10_000 }
              end
              
              describe "initial payment item" do
                subject { @init_payment_item }
                its(:amount) { should be == 10_000 }
                its(:to_account_id) { should be == @init_credit_item.from_account_id }
                its(:from_account_id) { should be == 1 }
                its(:action_date) { should be == Date.new(2008, 4, 20) }
              end
            end

            describe "response" do
              before do
                @action.call
              end
              subject { response }
              it { should be_success }
              its(:response_code) { should == 200 }
            end

            describe "the number of items" do
              it { expect { @action.call }.not_to change { Item.count } }
            end

            describe "updated item" do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.id } }
            end

            describe "payment item" do
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.amount } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.name } }
              it { expect { @action.call }.not_to change { Item.find(@credit_id).child_item.from_account_id } }
              it { expect { @action.call }.to change { Item.find(@credit_id).child_item.action_date }.by(1) }
            end

            describe "monthly profit losses" do
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 2, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 3, month: Date.new(2008, 2, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 4, month: Date.new(2008, 4, 1)).first.amount } }
              it { expect { @action.call }.not_to change { MonthlyProfitLoss.where(account_id: 1, month: Date.new(2008, 4, 1)).first.amount } }
            end
          end
        end
      end
    end
  end
end
