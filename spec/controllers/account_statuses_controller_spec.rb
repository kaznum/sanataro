# -*- coding: utf-8 -*-
require 'spec_helper'

describe AccountStatusesController do
  fixtures :users, :items, :accounts, :monthly_profit_losses
  
  describe "#show" do
    context "when not logined," do
      specify do
        User.should_receive(:find).with(nil).once.and_raise(ActiveRecord::RecordNotFound)
        xhr :get, :show
      end
    end

    context "when logined," do
      before do
        login
        xhr :get, :show
      end

      describe "response" do
        before { xhr :get, :show }

        subject {response}
        it {should render_template("account_statuses/show")}
      end

      describe "@account_statuses" do
        before do
          users(:user1).items.create!(:from_account_id => -1, :to_account_id => accounts(:bank1).id, :amount => -100, :action_date => Date.today, :name => 'unknown')
          xhr :get, :show
        end
        
        subject { assigns(:account_statuses)}
        it { should_not be_empty }
        its(['account']) { should_not be_nil }
        its(['outgo']) { should_not be_nil }
        its(['income']) { should_not be_nil }

        describe "unknown account" do
          it "does exist and amount is 100" do 
            unknown_account = Account.new do |a|
              a.name = I18n.t('label.unknown')
              a.order_no = 999999
              a.account_type = 'outgo'
            end
            outgoes = assigns(:account_statuses)['outgo']
            matches = outgoes.select { |account, amount| account.name == I18n.t('label.unknown') }
            matches.should have(1).entry
            matches[0][1].should be == 100
          end
        end
      end
    end
  end

  describe "#destroy" do
    context "when not logined," do
      specify do
        User.should_receive(:find).with(nil).once.and_raise(ActiveRecord::RecordNotFound)
        xhr :delete, :destroy
      end
    end

    context "when logined," do
      before do
        login
        xhr :delete, :destroy
      end

      describe "response" do
        subject {response}
        it {should render_template("account_statuses/destroy")}
      end
    end
  end
end
