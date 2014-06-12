require 'spec_helper'

describe BalanceSheetsController, :type => :controller do
  fixtures :users, :items, :accounts, :credit_relations, :monthly_profit_losses
  describe "#index" do
    context "when without login," do
      before do
        get :index
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "when logged in," do
      before do
        dummy_login
      end
      context "without month in params," do
        before do
          get :index
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "index" }
        end

        describe "assigns" do
          subject { assigns }

          describe '[:bs]' do
            subject { super()[:bs] }
            it { is_expected.not_to be_nil }
          end

          describe '[:accounts]' do
            subject { super()[:accounts] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_plus]' do
            subject { super()[:bs_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_minus]' do
            subject { super()[:bs_minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:plus]' do
            subject { super()[:plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:minus]' do
            subject { super()[:minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_plus]' do
            subject { super()[:total_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_minus]' do
            subject { super()[:total_minus] }
            it { is_expected.not_to be_nil }
          end
        end
      end

      context "without month in params and which has minus value in an account," do
        before do
          users(:user1).monthly_profit_losses.create(month: Date.new(2006, 12, 1), account_id: 1, amount: -2_000_000)
          get :index
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "index" }
        end

        describe "assigns" do
          subject { assigns }

          describe '[:bs]' do
            subject { super()[:bs] }
            it { is_expected.not_to be_nil }
          end

          describe '[:accounts]' do
            subject { super()[:accounts] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_plus]' do
            subject { super()[:bs_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_minus]' do
            subject { super()[:bs_minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:plus]' do
            subject { super()[:plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:minus]' do
            subject { super()[:minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_plus]' do
            subject { super()[:total_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_minus]' do
            subject { super()[:total_minus] }
            it { is_expected.not_to be_nil }
          end
        end
      end

      context "with month in params is invalid," do
        before do
          get :index, year: '2008', month: '13'
        end

        describe "response" do
          subject { response }
          it { is_expected.to redirect_to current_entries_url }
        end
      end

      context "with month(2008/2)," do
        before do
          get :index, year: '2008', month: '2'
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "index" }
        end

        describe "assigns" do
          subject { assigns }

          describe '[:bs]' do
            subject { super()[:bs] }
            it { is_expected.not_to be_nil }
          end

          describe '[:accounts]' do
            subject { super()[:accounts] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_plus]' do
            subject { super()[:bs_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:bs_minus]' do
            subject { super()[:bs_minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:plus]' do
            subject { super()[:plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:minus]' do
            subject { super()[:minus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_plus]' do
            subject { super()[:total_plus] }
            it { is_expected.not_to be_nil }
          end

          describe '[:total_minus]' do
            subject { super()[:total_minus] }
            it { is_expected.not_to be_nil }
          end
        end
      end
    end
  end

  describe "#show" do
    context "without login," do
      before do
        xhr :get, :show, id: accounts(:bank1).id
      end
      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "with login," do
      before do
        dummy_login
      end

      context "with year and month in params," do
        before do
          xhr :get, :show, id: accounts(:bank1).id.to_s, year: '2008', month: '2'
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "show" }
        end

        describe "assigns" do
          subject { assigns }

          describe '[:remain_amount]' do
            subject { super()[:remain_amount] }
            it { is_expected.to eq(8000) }
          end

          describe '[:items]' do
            subject { super()[:items] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_id]' do
            subject { super()[:account_id] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_id]' do
            subject { super()[:account_id] }
            it { is_expected.to eq(accounts(:bank1).id) }
          end
        end

        describe "assigns[:items]" do
          subject { assigns[:items] }
          specify do
            subject.each do |item|
              expect(item.from_account_id == accounts(:bank1).id ||
               item.to_account_id == accounts(:bank1).id).to be_truthy

              month0802 = Date.new(2008, 2)
              expect(item.action_date).to be_between month0802, month0802.end_of_month
            end
          end
        end
      end

      context "without year and month in params," do
        before do
          xhr :get, :show, id: accounts(:bank1).id.to_s
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "show" }
        end

        describe "assigns" do
          subject { assigns }

          describe '[:remain_amount]' do
            subject { super()[:remain_amount] }
            it { is_expected.not_to be_nil }
          end

          describe '[:items]' do
            subject { super()[:items] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_id]' do
            subject { super()[:account_id] }
            it { is_expected.not_to be_nil }
          end

          describe '[:account_id]' do
            subject { super()[:account_id] }
            it { is_expected.to eq(accounts(:bank1).id) }
          end
        end

        describe "assigns[:items]" do
          subject { assigns[:items] }
          specify do
            subject.each do |item|
              expect(item.from_account_id == accounts(:bank1).id ||
               item.to_account_id == accounts(:bank1).id).to be_truthy

              today = Date.today
              expect(item.action_date).to be_between today.beginning_of_month, today.end_of_month
            end
          end
        end
      end
    end
  end
end
