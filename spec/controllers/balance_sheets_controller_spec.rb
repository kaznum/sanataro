require 'spec_helper'

describe BalanceSheetsController do
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
        login
      end
      context "without month in params," do
        before do
          get :index
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "assigns" do
          subject { assigns }
          its([:bs]) { should_not be_nil }
          its([:accounts]) { should_not be_nil }
          its([:bs_plus]) { should_not be_nil }
          its([:bs_minus]) { should_not be_nil }
          its([:plus]) { should_not be_nil }
          its([:minus]) { should_not be_nil }
          its([:total_plus]) { should_not be_nil }
          its([:total_minus]) { should_not be_nil }
        end
      end
      
      context "without month in params and which has minus value in an account," do
        before do
          users(:user1).monthly_profit_losses.create(:month => Date.new(2006,12,1), :account_id => 1, :amount => -2000000)
          get :index
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "assigns" do
          subject { assigns }
          its([:bs]) { should_not be_nil }
          its([:accounts]) { should_not be_nil }
          its([:bs_plus]) { should_not be_nil }
          its([:bs_minus]) { should_not be_nil }
          its([:plus]) { should_not be_nil }
          its([:minus]) { should_not be_nil }
          its([:total_plus]) { should_not be_nil }
          its([:total_minus]) { should_not be_nil }
        end
      end

      context "with month in params is invalid," do
        before do
          get :index, :year => '2008', :month => '13'
        end

        describe "response" do
          subject { response }
          it { should redirect_to current_entries_url }
        end
      end

      context "with month(2008/2)," do
        before do
          get :index, :year => '2008', :month => '2'
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end

        describe "assigns" do
          subject { assigns }
          its([:bs]) { should_not be_nil }
          its([:accounts]) { should_not be_nil }
          its([:bs_plus]) { should_not be_nil }
          its([:bs_minus]) { should_not be_nil }
          its([:plus]) { should_not be_nil }
          its([:minus]) { should_not be_nil }
          its([:total_plus]) { should_not be_nil }
          its([:total_minus]) { should_not be_nil }
        end
      end
    end
  end

  describe "#show" do
    context "without login," do
      before do
        xhr :get, :show, :id => accounts(:bank1).id
      end
      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "with login," do
      before do
        login
      end
      context "without id," do
        before do
          xhr :get, :show, :year => 2008, :month => 2
        end

        it_should_behave_like "Unauthenticated Access by xhr"
      end

      context "with year and month in params," do
        before do
          xhr :get, :show, :id => accounts(:bank1).id.to_s, :year => '2008', :month => '2'
        end

        describe "response" do
          subject {response}
          it { should be_success }
          it { should render_template "show" }
        end

        describe "assigns" do
          subject { assigns }
          its([:remain_amount]) { should == 8000 }
          its([:items]) { should_not be_nil }
          its([:account_id]) { should_not be_nil }
          its([:account_id]) { should == accounts(:bank1).id}
        end

        describe "assigns[:items]" do
          subject { assigns[:items]}
          specify do 
            subject.each do |item|
              (item.from_account_id == accounts(:bank1).id ||
               item.to_account_id == accounts(:bank1).id).should be_true

              month0802 = Date.new(2008,2)
              item.action_date.should be_between month0802, month0802.end_of_month
            end
          end
        end
        
      end
      
      context "without year and month in params," do
        before do
          xhr :get, :show, :id => accounts(:bank1).id.to_s
        end

        describe "response" do
          subject {response}
          it { should be_success }
          it { should render_template "show" }
        end

        describe "assigns" do
          subject { assigns }
          its([:remain_amount]) { should_not be_nil }
          its([:items]) { should_not be_nil }
          its([:account_id]) { should_not be_nil }
          its([:account_id]) { should == accounts(:bank1).id}
        end

        describe "assigns[:items]" do
          subject { assigns[:items]}
          specify do 
            subject.each do |item|
              (item.from_account_id == accounts(:bank1).id ||
               item.to_account_id == accounts(:bank1).id).should be_true

              today = Date.today
              item.action_date.should be_between today.beginning_of_month, today.end_of_month
            end
          end
        end
      end
    end
  end
end
