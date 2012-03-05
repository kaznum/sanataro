# -*- coding: utf-8 -*-
require 'spec_helper'

describe Api::BudgetsController do
  fixtures :users
  
  describe "show" do
    context "before login" do
      before do
        get :show, :id => 200802, :format => :json
      end
      
      it_should_behave_like "Unauthenticated Access"
    end
    
    context "after login" do
      before do
        login
      end
      
      context "id is not specified" do
        before do
          get :show, :format => :json
        end
        
        it_should_behave_like "Unauthenticated Access"
      end
      
      context "id's length is not 6 digit" do
        before do
          get :show, :id => '21222', :format => :json
        end
        
        it_should_behave_like "Unauthenticated Access"
      end
      
      context "id's initial char is not 0" do
        before do
          get :show, :id => '021222', :format => :json
        end
        
        it_should_behave_like "Unauthenticated Access"
      end
      
      context "id has non-numeric char" do
        before do
          get :show, :id => '2008a2', :format => :json
        end
        
        it_should_behave_like "Unauthenticated Access"
      end
      
      context "id does not mean correct year-month" do
        before do
          get :show, :id => '200815', :format => :json
        end
        
        it_should_behave_like "Unauthenticated Access"
      end
      
      context "There is no data to send" do
        before do
          Account.destroy_all
          get :show, :id => '200301', :format => :json
        end
        subject { response }
        it {  should be_success }
        its(:body) { should == "[]"}
      end
      
      context "There are data to send." do
        before do
          Account.destroy_all
          @user = users(:user1)
          account1 = @user.accounts.create!(:name => "その1", :active => true, :account_type => 'account', :order_no => 10)
          account2 = @user.accounts.create!(:name => "その2", :active => true, :account_type => 'income', :order_no => 20)
          account3 = @user.accounts.create!(:name => "その3", :active => true, :account_type => 'account', :order_no => 30)
          account4 = @user.accounts.create!(:name => "その4", :active => true, :account_type => 'outgo', :order_no => 40)
          
          @user.monthly_profit_losses.create(:month => Date.new(1999,5), :account_id => account1.id, :amount => -300 )
          @user.monthly_profit_losses.create(:month => Date.new(1988,6), :account_id => account1.id, :amount => -100 )
          @user.monthly_profit_losses.create(:month => Date.new(1999,1), :account_id => account2.id, :amount => -900 )
          @user.monthly_profit_losses.create(:month => Date.new(1999,1), :account_id => account3.id, :amount => 900 )
          @user.monthly_profit_losses.create(:month => Date.new(1999,1), :account_id => account4.id, :amount => 200 )
          @mpl_unknown = @user.monthly_profit_losses.create(:month => Date.new(1999,1), :account_id => -1, :amount => -800 )
        end
        
        context "budget_type is not specified." do
          before do 
            get :show, :id => '199901', :format => :json
          end
          
          describe "response" do
            subject { response }
            it {  should be_success }
            specify do
              ActiveSupport::JSON.decode(subject.body).should == [{"label" => "その2", "data" => 900},{"label" => I18n.t("label.unknown_income"), "data" => 800}]
            end
          end
        end
        
        context "budget_type is 'outgo'" do
          before do
            @mpl_unknown.update_attributes(amount: 500)

            get :show, :id => '199901', :format => :json, :budget_type => 'outgo'
          end

          describe "response" do
            subject { response }
            it {  should be_success }
            specify do
              ActiveSupport::JSON.decode(subject.body).should == [{"label" => "その4", "data" => 200}, {"label" =>  I18n.t("label.unknown_outgoing"), "data" => 500}]
            end
          end
        end
      end
    end
  end
end
