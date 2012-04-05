# -*- coding: utf-8 -*-
require 'spec_helper'

describe Settings::AccountsController do
  fixtures :all

  describe "#index" do
    context "before login," do
      before do
        get :index, :account_type => nil
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "after login," do
      before do
        login
      end
      
      context "when params[:account_type] is invalid," do
        before do
          get :index, :account_type => 'not_exist'
        end

        it_should_behave_like "Unauthenticated Access"

        describe "@accounts" do
          subject { assigns(:accounts)}
          it { should be_nil }
        end
      end

      ['account', 'outgo','income'].each do |type|
        shared_examples_for "account_type = '#{type}'" do
          subject { response }
          it { should be_success }
          it { should render_template('index') }

          describe "@account_type" do
            subject { assigns(:account_type)}
            it { should be == type }
          end
          
          describe "@accounts" do
            subject { assigns(:accounts) }
            it { should_not be_empty }
            specify { subject.each do |a|
                a.account_type.should be == type
              end
            }
          end
        end
      end
      
      context "when params[:account_type] is nil," do
        before do
          get :index, :account_type => nil
        end
        it_should_behave_like "account_type = 'account'"
      end

      context "when params[:account_type] == 'account'," do
        before do
          get :index, :account_type => 'account'
        end
        it_should_behave_like "account_type = 'account'"
      end

      context "when params[:account_type] == 'outgo'," do
        before do
          get :index, :account_type => 'outgo'
        end

        it_should_behave_like "account_type = 'outgo'"
      end

      context "when params[:account_type] == 'income'," do
        before do
          get :index, :account_type => 'income'
        end

        it_should_behave_like "account_type = 'income'"
      end
    end
  end

  describe "#create" do

    context "before login," do
      before do
        xhr :post, :create, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10' 
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login," do
      before do
        login
      end
      
     context "via xhr," do
        context "with valid params," do 
          before do
            @before_count = Account.count
            @before_bgcolors_count = User.find(session[:user_id]).get_categorized_accounts[:account_bgcolors].size
            xhr :post, :create, :account_type => 'account', :account_name => 'hogehoge', :order_no => '10'
          end

          describe "response" do
            subject { response }
            it { should redirect_by_js_to settings_accounts_url(:account_type => 'account')}
          end

          describe "count of accounts" do
            subject { Account.count }
            it { should be == @before_count + 1 }
          end

          describe "count of bgcolors" do
            subject { User.find(session[:user_id]).get_categorized_accounts[:account_bgcolors].size }
            it { should be == @before_bgcolors_count }
          end
        end
        
        context "with invalid params," do 
          before do
            @before_count = Account.count
            @before_bgcolors_count = User.find(session[:user_id]).get_categorized_accounts[:account_bgcolors].size
            xhr :post, :create, :account_type => 'acc', :account_name => 'hogehoge', :order_no => '10'
          end
          
          describe "response" do
            subject { response }
            it { should render_js_error :id => "add_warning", :default_message => I18n.t("error.input_is_invalid") }
          end

          describe "count of accounts" do
            subject { Account.count }
            it { should be == @before_count }
          end

          describe "count of bgcolors" do
            subject { User.find(session[:user_id]).get_categorized_accounts[:account_bgcolors].size }
            it { should be == @before_bgcolors_count }
          end
        end
      end
    end
  end

  describe "#edit" do
    context "before login," do
      before do
        xhr :get, :edit, :id => accounts(:bank1).id
      end

      subject { response }
      it { should redirect_by_js_to login_url }
    end

    context "after login," do
      before do
        login
      end

      context "when method is xhr get," do

        context "with invalid params[:id]," do
          before do
            xhr :get, :edit
          end

          subject { response }
          it { should redirect_by_js_to login_url }
        end

        context "with valid params[:id]," do
          before do
            xhr :get, :edit, :id => accounts(:bank1).id
          end

          describe "response" do 
            subject { response }
            it { should render_template "edit" }
          end

          describe "@account" do
            subject { assigns(:account)}
            its(:id) { should be == accounts(:bank1).id }
          end
          
        end
      end
    end
  end
  
  describe "#destroy" do
    before do
      @dummy = users(:user1).accounts.create!(:name => 'hogehoge', :account_type => 'account',
                                              :order_no => 100)
    end
    context "before login," do
      before do 
        xhr :delete, :destroy, :id => @dummy.id
      end
      describe "response" do
        subject { response }
        it { should redirect_by_js_to login_url }
      end
    end
    
    context "after login" do
      before do
        login
      end
     
      context "when method is xhr delete," do
        context "when params[:id] is not correct," do
          before do
            xhr :delete, :destroy, :id => 31432412
          end
          it_should_behave_like "Unauthenticated Access by xhr"
        end
        
        context "when the account is not used yet," do
          before do
            @before_count = Account.count
            xhr :delete, :destroy, :id => @dummy.id
          end
          
          describe "response" do 
            subject { response }
            it { should render_template "destroy" }
          end

          describe "Account.count" do
            subject { Account.count }
            it { should be == @before_count - 1 }
          end
        end

        context "when the account is already used," do
          before do
            @before_count = Account.count
            xhr :delete, :destroy, :id => accounts(:bank1).id
          end
          
          describe "response" do 
            subject { response }
            it { should render_js_error :id => "add_warning" }
          end
          
          describe "Account.count" do
            subject { Account.count }
            it { should be == @before_count }
          end
        end

        context "when the account has relation to credit card," do
          before do
            Item.destroy_all
            @before_count = Account.count
            @account = accounts(:bank1)
            xhr :delete, :destroy, :id => @account.id
          end
          
          describe "response" do
            subject { response }
            it { should render_js_error :id => "add_warning", :errors => ["クレジットカード支払い情報に関連づけられているため、削除できません。"] }
          end
          
          describe "Account.count" do
            subject { Account.count }
            it { should be == @before_count }
          end
        end
      end
    end
    
  end
  
  describe "#update" do
    context "before login," do
      before do
        xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '10', :bgcolor => '222222'
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end
    
    context "after login," do
      before do
        login
      end

      context "with xhr put method," do

        context "with invalid params[:id]," do
          before do 
            xhr :put, :update, :id => 4314321, :account_name => 'hogehoge', :order_no => '100', :bgcolor => "cccccc", :use_bgcolor => '1'
          end

          it_should_behave_like "Unauthenticated Access by xhr"
        end
        
        shared_examples_for "Updated Successfully" do
          describe "response" do
            subject { response }
            it { should redirect_by_js_to settings_accounts_url(:account_type => accounts(:bank1).account_type) } 
          end

          describe "@user.get_categorized_accounts" do
            before do
              @separated_accounts = assigns(:user).get_categorized_accounts
            end
            
            describe "separated_accounts[:all_accounts][id]" do
              subject { @separated_accounts[:all_accounts][accounts(:bank1).id] }
              it { should be == 'hogehoge'}
            end

          end

          describe "updated account record" do
            subject { Account.find(accounts(:bank1).id) }
            its(:name) { should be == 'hogehoge'}
            its(:order_no) { should be 100 }
          end
        end
        
        context "with valid params," do
          context "with bgcolor," do 
            before do 
              xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '100', :bgcolor => "cccccc", :use_bgcolor => '1'
            end

            it_should_behave_like "Updated Successfully"
            
            describe "assigns(:user).get_categorized[:account_bgcolors][id]" do
              subject { assigns(:user).get_categorized_accounts[:account_bgcolors][accounts(:bank1).id] }
              it { should be == 'cccccc'}
            end
            
            describe "updated account record" do
              subject { Account.find(accounts(:bank1).id) }
              its(:bgcolor) { should be == 'cccccc' }
            end
          end

          context "without use_bgcolor," do
            before do 
              xhr :put, :update, :id => accounts(:bank1).id, :account_name => 'hogehoge', :order_no => '100',  :bgcolor => "cccccc"
            end

            it_should_behave_like "Updated Successfully"

            describe "assigns(:user).get_categorized_accounts[:account_bgcolors][id]" do
              subject { assigns(:user).get_categorized_accounts[:account_bgcolors][accounts(:bank1).id] }
              it { should be_nil }
            end
            
            describe "updated account record" do
              subject { Account.find(accounts(:bank1).id) }
              its(:bgcolor) { should be_nil }
            end
          end
        end
        
        context "with invalid params(name is empty)," do
          before do
            @orig_account = Account.find(accounts(:bank1).id)
            xhr :put, :update, :id => accounts(:bank1).id, :account_name => '', :order_no => '100', :bgcolor => "cccccc", :use_bgcolor => '1'
          end

          describe "response" do
            subject { response}
            it { should render_js_error :id => "account_#{accounts(:bank1).id}_warning", :default_message => I18n.t("error.input_is_invalid") }
          end

          describe "DB Record" do
            subject { Account.find(accounts(:bank1).id) }
            its(:name) { should be == @orig_account.name }
            its(:order_no) { should be == @orig_account.order_no }
            its(:account_type) { should be == @orig_account.account_type }
            its(:bgcolor) { should be == @orig_account.bgcolor }
          end
        end
      end
    end
  end
  
  describe "#show" do
    context "before login," do
      before do
        xhr :get, :show, :id => accounts(:bank1).id
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login," do
      before do
        login
      end
      
      context "when accessed by xhr get," do
        context "with valid params," do 
          before do
            xhr :get, :show, :id => accounts(:bank1).id
          end

          describe "response" do
            subject { response }
            it { should render_template "show" }
          end

          describe "@account" do
            subject { assigns(:account) }
            it { should_not be_nil }
            its(:name) { should be == accounts(:bank1).name }
          end
        end

        context "without params[:id]," do
          before do
            xhr :get, :show
          end

          subject { response }
          it { should redirect_by_js_to login_url }
        end

        context "without the invalid params[:id]," do
          before do
            xhr :get, :show, :id => 992143
          end

          subject { response }
          it { should redirect_by_js_to login_url }
        end
      end
    end
  end
end
