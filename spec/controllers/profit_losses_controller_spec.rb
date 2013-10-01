# -*- coding: utf-8 -*-
require 'spec_helper'

describe ProfitLossesController do
  fixtures :users, :items, :accounts, :monthly_profit_losses, :credit_relations

  describe "#index" do
    context "when not logged in," do
      before do
        get :index
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "when logged in," do
      before do
        login
      end
      context "when month is not specified," do
        before do
          get :index
        end

        describe "response" do
          subject {response}
          it { should be_success }
          it { should render_template('index') }
        end

        describe "instance varriables" do
          subject { assigns }
          its([:m_pls]) { should_not be_nil }
          its([:account_incomes]) { should_not be_nil }
          its([:total_income]) { should_not be_nil }
          its([:account_expenses]) { should_not be_nil }
          its([:total_expense]) { should_not be_nil }
        end
      end

      context "when month is invalid," do
        before do
          get :index, year: '2008', month: '13'
        end

        describe "response" do
          subject { response }
          it { should redirect_to current_entries_url }
        end
      end

      context "when valid month is specified," do
        context "and with common condition," do
          before do
            get :index, year: '2008', month: '2'
          end
          describe "response" do
            subject { response}
            it { should be_success }
            it { should render_template('index')}
          end

          describe "assigned variables" do
            subject { assigns }
            its([:m_pls]) { should_not be_nil}
            its([:account_incomes]) { should_not be_nil}
            its([:total_income]) { should_not be_nil}
            its([:account_expenses]) { should_not be_nil}
            its([:total_expense]) { should_not be_nil}
          end
        end

        context "and Unknown accounts amount < 0," do
          before do
            get :index, year: '2008', month: '2'
          end

          describe "unknown account in assigned variables" do
            subject { assigns[:account_incomes] }
            it { should be_any { |a| a.id == -1 } }
            specify { subject.find{ |a| a.id == -1 }.name.should == I18n.t("label.unknown_income") }
          end
        end

        context "and Unknown accounts amount > 0," do
          before do
            MonthlyProfitLoss.find(ActiveRecord::FixtureSet.identify(:unknown200802)).update_attributes(amount: 5000)
            get :index, year: '2008', month: '2'
          end

          describe "unknown account in assigned variables" do
            subject { assigns[:account_expenses] }
            it { should be_any { |a| a.id == -1 } }
            specify { subject.find{ |a| a.id == -1 }.name.should == I18n.t("label.unknown_expense") }
          end
        end
      end
    end
  end

  describe "#show" do
    context "when not logged in," do
      before do
        xhr :get, :show, id: accounts(:bank1).id, year: '2008', month: '2'
      end

      describe "response" do
        subject { response }
        it { should render_template("common/redirect") }
      end
    end

    context "when logged in," do
      before do
        login
      end

      context "when correct id is specified," do
        context "when year, month are specified," do
          before do
            xhr :get, :show, id: accounts(:expense3).id.to_s, year: '2008', month: '2'
          end
          describe "response" do
            subject { response }
            it {should render_template "show"}
          end

          describe "assigned variables" do
            subject { assigns }
            its([:items]) {should_not be_nil}
            its([:account_id]) {should_not be_nil}
            its([:account_id]) { should be accounts(:expense3).id }

            describe "items" do
              subject { assigns[:items] }
              specify do
                subject.each do |item|
                  item.to_account_id.should be(accounts(:expense3).id)
                  item.action_date.should be_between(Date.new(2008, 2), Date.new(2008,2).end_of_month)
                end
              end
            end
          end
        end

        context "when year, month are not specified," do
          before do
            xhr :get, :show, id: accounts(:expense3).id.to_s
          end

          describe "response" do
            subject { response }
            it { should be_success }
            it { should render_template "show" }
          end
          describe "assigned variables" do
            subject { assigns }
            its([:items]) { should_not be_nil }
            its([:account_id]) { should_not be_nil }
            its([:account_id]) { should be accounts(:expense3).id }

            describe "items" do
              subject { assigns(:items)}
              specify do
                subject.each do |item|
                  item.to_account_id.should be accounts(:expense3).id
                  item.action_date.should be_between(Date.today.beginning_of_month, Date.today.end_of_month)
                end
              end
            end
          end
        end
      end
    end
  end
end
