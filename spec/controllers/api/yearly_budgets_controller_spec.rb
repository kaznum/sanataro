# coding: utf-8
require 'spec_helper'

describe Api::YearlyBudgetsController do
  fixtures :users
  
  describe "#show" do
    context "before login," do
      before do
        get :show, id: "200802", budget_type: "outgo", format: :json
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "after login," do
      before do
        login
      end

      context "when id is not specified," do
        before do
          get :show, format: :json, budget_type: "outgo"
        end
        it_should_behave_like "Unauthenticated Access"
      end

      context "when budget_type is invalid," do
        before do
          get :show, id: "200802", budget_type: "out", format: :json
        end

        it_should_behave_like "Unauthenticated Access"
      end

      context "when id is invalid format," do
        before do
          get :show, id: "2008", budget_type: "outgo", format: :json
        end
        it_should_behave_like "Unauthenticated Access"
      end

      context "when params are valid," do
        context "and budget_type is outgo," do 
          context "and there is no data to send," do 
            before do
              Account.destroy_all
              get :show, id: "200802", budget_type: "outgo", format: :json
            end
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(2008,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(1).keys
                json["account_-1"]["label"].should == "Unknown"
                json["account_-1"]["data"].should have(12).entries
                json["account_-1"]["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
              }
            end
          end

          context "when there are some data to send," do 
            before do
              Account.destroy_all

              @user = users(:user1)
              accs = @user.accounts
              account1 = accs.create!(name: "その1", active: true,
                                      account_type: 'account', order_no: 10)
              account2 = accs.create!(name: "その2", active: true,
                                      account_type: 'income', order_no: 20)
              account3 = accs.create!(name: "その3", active: true,
                                      account_type: 'account', order_no: 30)
              @outgo_account = account4 = accs.create!(name: "その4", active: true,
                                      account_type: 'outgo', order_no: 40)

              pls = @user.monthly_profit_losses
              pls.create!(month: Date.new(1999,5), account_id: account1.id, amount: -300 )
              pls.create!(month: Date.new(1988,6), account_id: account1.id, amount: -100 )
              pls.create!(month: Date.new(1999,1), account_id: account2.id, amount: -900 )
              pls.create!(month: Date.new(1999,1), account_id: account3.id, amount: 900 )
              pls.create!(month: Date.new(1999,1), account_id: account4.id, amount: 200 )
              pls.create!(month: Date.new(1999,1), account_id: -1, amount: 800 )
              pls.create!(month: Date.new(1999,2), account_id: -1, amount: -300 )
              
              get :show, id: "199902", budget_type: "outgo", format: :json
            end
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(1999,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(2).keys
                json["account_-1"]["label"].should == "Unknown"
                json["account_-1"]["data"].should have(12).entries
                json["account_-1"]["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(1).to_time.to_i*1000, 800])
                json["account_-1"]["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
                json_income = json["account_#{@outgo_account.id}"]
                json_income["label"].should == "その4"
                json_income["data"].should have(12).entries
                json_income["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json_income["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json_income["data"].should include([date.months_ago(1).to_time.to_i*1000, 200])
                json_income["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
              }
            end
          end
        end
        
        context "when budget_type is income," do 
          context "when there is no data to send," do 
            before do
              Account.destroy_all
              MonthlyProfitLoss.destroy_all
              get :show, id: "200802", budget_type: "income", format: :json
            end
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(2008,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(1).keys
                json["account_-1"]["label"].should == "Unknown"
                json["account_-1"]["data"].should have(12).entries
                json["account_-1"]["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
              }
            end
          end

          context "when there is some data to send," do 
            before do
              Account.destroy_all
              @user = users(:user1)
              accs = @user.accounts
              account1 = accs.create!(name: "その1", active: true,
                                      account_type: 'account', order_no: 10)
              @income_account = account2 = accs.create!(name: "その2", active: true,
                                      account_type: 'income', order_no: 20)
              account3 = accs.create!(name: "その3", active: true,
                                      account_type: 'account', order_no: 30)
              account4 = accs.create!(name: "その4", active: true,
                                      account_type: 'outgo', order_no: 40)

              pls = @user.monthly_profit_losses
              pls.create!(month: Date.new(1999,5), account_id: account1.id, amount: -300 )
              pls.create!(month: Date.new(1988,6), account_id: account1.id, amount: -100 )
              pls.create!(month: Date.new(1999,1), account_id: account2.id, amount: -900 )
              pls.create!(month: Date.new(1999,1), account_id: account3.id, amount: 900 )
              pls.create!(month: Date.new(1999,1), account_id: account4.id, amount: 200 )
              pls.create!(month: Date.new(1999,1), account_id: -1, amount: -800 )
              
              get :show, id: "199902", budget_type: "income", format: :json
            end
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(1999,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(2).keys
                json["account_-1"]["label"].should == "Unknown"
                json["account_-1"]["data"].should have(12).entries
                json["account_-1"]["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json["account_-1"]["data"].should include([date.months_ago(1).to_time.to_i*1000, 800])
                json_income = json["account_#{@income_account.id}"]
                json_income["label"].should == "その2"
                json_income["data"].should have(12).entries
                json_income["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                json_income["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                json_income["data"].should include([date.months_ago(1).to_time.to_i*1000, 900])
                json_income["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
              }
            end
          end
        end

        context "when budget_type is total," do 
          context "when there is no data to send," do 
            before do
              Account.destroy_all
              MonthlyProfitLoss.destroy_all
              get :show, id: "200802", budget_type: "total", format: :json
            end
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(2008,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(3).keys
                json["outgo"]["label"].should == "支出"
                json["income"]["label"].should == "収入"
                json["total"]["label"].should == "収支"
                ["outgo", "income", "total"].each do |type|
                  json[type]["data"].should have(12).entries
                  json[type]["data"].should include([date.months_ago(11).to_time.to_i*1000, 0])
                  json[type]["data"].should include([date.months_ago(5).to_time.to_i*1000, 0])
                  json[type]["data"].should include([date.months_ago(0).to_time.to_i*1000, 0])
                end
              }
            end
          end
          context "when there is some data to send," do 
            before do
              Account.destroy_all
              @user = users(:user1)
              accs = @user.accounts
              account1 = accs.create!(name: "その1", active: true,
                                      account_type: 'account', order_no: 10)
              account2 = accs.create!(name: "その2", active: true,
                                      account_type: 'income', order_no: 20)
              account3 = accs.create!(name: "その3", active: true,
                                      account_type: 'account', order_no: 30)
              account4 = accs.create!(name: "その4", active: true,
                                      account_type: 'outgo', order_no: 40)

              pls = @user.monthly_profit_losses
              pls.create!(month: Date.new(1999,5), account_id: account1.id, amount: -300 )
              pls.create!(month: Date.new(1988,6), account_id: account1.id, amount: -100 )
              pls.create!(month: Date.new(1999,1), account_id: account2.id, amount: -900 )
              pls.create!(month: Date.new(1999,1), account_id: account3.id, amount: 900 )
              pls.create!(month: Date.new(1999,1), account_id: account4.id, amount: 200 )
              pls.create!(month: Date.new(1999,1), account_id: -1, amount: -800 )
              get :show, id: "199902", budget_type: "total", format: :json
            end
            
            describe "response" do
              subject { response }
              it { should be_success }
              its(:body) {
                date = Date.new(1999,2)
                json = ActiveSupport::JSON.decode(subject)
                json.should have(3).keys
                json["outgo"]["label"].should == "支出"
                json["income"]["label"].should == "収入"
                json["total"]["label"].should == "収支"
                ["outgo", "income", "total"].each do |type|
                  json[type]["data"].should have(12).entries
                end
                json["outgo"]["data"].should include([Date.new(1999,1).to_time.to_i*1000, 200])
                json["outgo"]["data"].should include([Date.new(1999,2).to_time.to_i*1000, 0])
                json["outgo"]["data"].should include([Date.new(1998,3).to_time.to_i*1000, 0])
                json["income"]["data"].should include([Date.new(1999,1).to_time.to_i*1000, 1700])
                json["income"]["data"].should include([Date.new(1999,2).to_time.to_i*1000, 0])
                json["income"]["data"].should include([Date.new(1998,3).to_time.to_i*1000, 0])
                json["total"]["data"].should include([Date.new(1999,1).to_time.to_i*1000, 1500])
                json["total"]["data"].should include([Date.new(1999,2).to_time.to_i*1000, 0])
                json["total"]["data"].should include([Date.new(1998,3).to_time.to_i*1000, 0])
              }
            end
          end
        end
      end
    end
  end
end
