require 'spec_helper'

describe StatController do
  include FakedUser
  
  fixtures :accounts, :items, :monthly_profit_losses, :credit_relations, :autologin_keys
  
  describe "index" do
    context "before login" do
      before do
        get :index
      end
      it_should_behave_like "Unauthenticated Access"
    end

    context "after login" do
      before do
        login
        get :index
      end

      subject {response}
      it { should redirect_to current_entries_url }
    end
  end


  describe "show_yearly_bs_graph" do
    context "without login" do
      before do
        xhr :post, :show_yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :type=>'total', :year => 2008, :month => 2
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login" do
      before do
        login
      end

      context "without ID" do
        before do
          xhr :post, :show_yearly_bs_graph, :year => 2008, :month => 2
        end

        it_should_behave_like "Unauthenticated Access by xhr"
      end

      context "without month" do
        before do
          xhr :post, :show_yearly_bs_graph, :type => 'total', :year => 2008
        end

        it_should_behave_like "Unauthenticated Access by xhr"
      end

      context "type is total" do
        before do
          xhr :post, :show_yearly_bs_graph, :type=>'total', :year => 2008, :month => 2
        end

        subject {response}
        it {should render_template 'show_yearly_bs_graph'}
      end

      context "account_id is specified" do
        before do
          xhr :post,  :show_yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
        end

        subject {response}
        it {should render_template 'show_yearly_bs_graph'}
      end
    end
  end

  describe "yearly_bs_graph" do
    context "before login" do 
      before do
        get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "after login" do 
      before do
        login
      end

      context "without id" do
        before do
          get :yearly_bs_graph, :year => 2008, :month => 2
        end

        it_should_behave_like "Unauthenticated Access"
      end

      context "with invalid id" do
        before do
          get :yearly_bs_graph, :year => 2008, :month => 2, :account_id => '1000000'
        end

        it_should_behave_like "Unauthenticated Access"
      end

      context "without month" do
        before do
          get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008
        end

        it_should_behave_like "Unauthenticated Access"
      end

      pending("Ruby1.9 & rmagick do not work", :if => RUBY_VERSION >= "1.9") do 
        context "with type == 'total'" do
          before do
            get :yearly_bs_graph, :type=>'total', :year => 2008, :month => 2
          end

          subject {response}
          it {should be_success}
        end

        context "with valid account_id" do
          before do
            get :yearly_bs_graph, :account_id=>accounts(:bank1).id.to_s, :year => 2008, :month => 2
          end
          subject {response}
          it {should be_success}
        end
      end
    end
  end


  describe "change_month" do
    context "without login" do
      before do
        xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :pl
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login," do
      before do
        login
      end

      context "xhr request," do
        before do
          xhr :post, :change_month, :year=>'2008', :month=>'2', :current_action => :index
        end
        
        subject { response }
        it {should redirect_by_js_to @controller.url_for(:action => :index, :year => '2008', :month => '2')}
      end

      context "get request for action: aaa on 2008/2," do
        before do
          get :change_month, :year=>'2008', :month=>'2', :current_action => 'aaa'
        end
        
        subject { response }
        it {should redirect_to @controller.url_for(:action => 'aaa', :year => '2008', :month => '2')}
      end

      context "post request for action: bbb on 2008/2," do
        before do
          post :change_month, :year=>'2008', :month=>'2', :current_action => 'bbb'
        end
        
        subject { response }
        it {should redirect_to @controller.url_for(:action => 'bbb', :year => '2008', :month => '2')}
      end
    end
  end
  
end
