# - * - coding: utf-8 - * -

require 'spec_helper'

describe ChartData::YearlyAssetsController, type: :controller do
  fixtures :users

  describe '#show' do
    context 'before login,' do
      before do
        get :show, id: '200802', format: :json
      end

      it_should_behave_like 'Unauthenticated Access'
    end

    context 'after login,' do
      before do
        dummy_login
      end

      context 'when id is invalid format,' do
        before do
          get :show, id: '2008', format: :json
        end
        it_should_behave_like 'Not Acceptable'
      end

      context 'when params are valid,' do
        context 'there is no assets information' do
          before do
            Item.destroy_all
            CreditRelation.destroy_all
            Account.destroy_all
            get :show, id: '199902', format: :json
          end
          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'response.body' do
            subject { response.body }
            it {
              date = Date.new(1999, 2)
              json = ActiveSupport::JSON.decode(subject)
              expect(json.keys.size).to eq(1)
              ['total'].each do |key|
                expect(json[key]['data'].entries.size).to eq(12)
                expect(json[key]['data']).to include([date.months_ago(11).to_time.to_i * 1000, 0])
              end
            }
          end
        end

        context 'when there is some assets information,' do
          before do
            Item.destroy_all
            CreditRelation.destroy_all
            Account.destroy_all

            @user = users(:user1)
            @account1 = @user.bankings.create!(name: 'その1', active: true, order_no: 10)
            @account2 = @user.incomes.create!(name: 'その2', active: true, order_no: 20)
            @account3 = @user.bankings.create!(name: 'その3', active: true, order_no: 30)
            @account4 = @user.expenses.create!(name: 'その4', active: true, order_no: 40)

            pls = @user.monthly_profit_losses
            pls.create!(month: Date.new(1998, 1), account_id: @account1.id, amount: -300)
            pls.create!(month: Date.new(1998, 6), account_id: @account1.id, amount: -100)
            pls.create!(month: Date.new(1999, 1), account_id: @account2.id, amount: -900)
            pls.create!(month: Date.new(1999, 1), account_id: @account3.id, amount: 900)
            pls.create!(month: Date.new(1999, 1), account_id: @account4.id, amount: 200)
            pls.create!(month: Date.new(1999, 1), account_id: -1, amount: 800)
            pls.create!(month: Date.new(1999, 2), account_id: -1, amount: -300)
            pls.create!(month: Date.new(2000, 5), account_id: @account1.id, amount: -300)

            get :show, id: '199902', format: :json
          end

          describe 'response' do
            subject { response }
            it { is_expected.to be_success }
          end

          describe 'response.body' do
            subject { response.body }
            it {
              date = Date.new(1999, 2)
              json = ActiveSupport::JSON.decode(subject)
              expect(json.keys.size).to eq(3)
              ["account_#{@account1.id}", "account_#{@account3.id}", 'total'].each do |key|
                expect(json[key]['data'].entries.size).to eq(12)
              end

              expect(json["account_#{@account1.id}"]['label']).to eq('その1')
              expect(json["account_#{@account3.id}"]['label']).to eq('その3')
              expect(json['total']['label']).to eq('合計')

              expect(json["account_#{@account1.id}"]['data']).to include([date.months_ago(9).to_time.to_i * 1000, -300])
              expect(json["account_#{@account1.id}"]['data']).to include([date.months_ago(8).to_time.to_i * 1000, -400])
              expect(json["account_#{@account1.id}"]['data']).to include([date.months_ago(0).to_time.to_i * 1000, -400])

              expect(json['total']['data']).to include([date.months_ago(9).to_time.to_i * 1000, -300])
              expect(json['total']['data']).to include([date.months_ago(8).to_time.to_i * 1000, -400])
              expect(json['total']['data']).to include([date.months_ago(2).to_time.to_i * 1000, -400])
              expect(json['total']['data']).to include([date.months_ago(1).to_time.to_i * 1000, 500])
            }
          end
        end
      end
    end
  end
end
