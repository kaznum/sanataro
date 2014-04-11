# - * - coding: utf-8 - * -
require 'spec_helper'

describe ChartData::YearlyAssetsController do
  fixtures :users

  describe "#show" do
    context "before login," do
      before do
        get :show, id: "200802", format: :json
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "after login," do
      before do
        dummy_login
      end

      context "when id is invalid format," do
        before do
          get :show, id: "2008", format: :json
        end
        it_should_behave_like "Not Acceptable"
      end

      context "when params are valid," do
        context "there is no assets information" do
          before do
            Item.destroy_all
            CreditRelation.destroy_all
            Account.destroy_all
            get :show, id: "199902", format: :json
          end
          describe "response" do
            subject { response }
            it { should be_success }
          end

          describe "response.body" do
            subject { response.body }
            it {
              date = Date.new(1999, 2)
              json = ActiveSupport::JSON.decode(subject)
              json.should have(1).keys
              ["total"].each do |key|
                json[key]["data"].should have(12).entries
                json[key]["data"].should include([date.months_ago(11).to_time.to_i * 1000, 0])
              end
            }
          end
        end

        context "when there is some assets information," do
          before do
            Item.destroy_all
            CreditRelation.destroy_all
            Account.destroy_all

            @user = users(:user1)
            @account1 = @user.bankings.create!(name: "その1", active: true, order_no: 10)
            @account2 = @user.incomes.create!(name: "その2", active: true, order_no: 20)
            @account3 = @user.bankings.create!(name: "その3", active: true, order_no: 30)
            @account4 = @user.expenses.create!(name: "その4", active: true, order_no: 40)

            pls = @user.monthly_profit_losses
            pls.create!(month: Date.new(1998, 1), account_id: @account1.id, amount: -300)
            pls.create!(month: Date.new(1998, 6), account_id: @account1.id, amount: -100)
            pls.create!(month: Date.new(1999, 1), account_id: @account2.id, amount: -900)
            pls.create!(month: Date.new(1999, 1), account_id: @account3.id, amount: 900)
            pls.create!(month: Date.new(1999, 1), account_id: @account4.id, amount: 200)
            pls.create!(month: Date.new(1999, 1), account_id: -1, amount: 800)
            pls.create!(month: Date.new(1999, 2), account_id: -1, amount: -300)
            pls.create!(month: Date.new(2000, 5), account_id: @account1.id, amount: -300)

            get :show, id: "199902", format: :json
          end

          describe "response" do
            subject { response }
            it { should be_success }
          end

          describe "response.body" do
            subject { response.body }
            it {
              date = Date.new(1999, 2)
              json = ActiveSupport::JSON.decode(subject)
              json.should have(3).keys
              ["account_#{@account1.id}", "account_#{@account3.id}", "total"].each do |key|
                json[key]["data"].should have(12).entries
              end

              json["account_#{@account1.id}"]["label"].should be == "その1"
              json["account_#{@account3.id}"]["label"].should be == "その3"
              json["total"]["label"].should be == "合計"

              json["account_#{@account1.id}"]["data"].should include([date.months_ago(9).to_time.to_i * 1000, -300])
              json["account_#{@account1.id}"]["data"].should include([date.months_ago(8).to_time.to_i * 1000, -400])
              json["account_#{@account1.id}"]["data"].should include([date.months_ago(0).to_time.to_i * 1000, -400])

              json["total"]["data"].should include([date.months_ago(9).to_time.to_i * 1000, -300])
              json["total"]["data"].should include([date.months_ago(8).to_time.to_i * 1000, -400])
              json["total"]["data"].should include([date.months_ago(2).to_time.to_i * 1000, -400])
              json["total"]["data"].should include([date.months_ago(1).to_time.to_i * 1000, 500])
            }
          end
        end
      end
    end
  end
end
