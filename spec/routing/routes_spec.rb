require 'spec_helper'

describe :routes do

  describe "root" do
    describe 'GET /' do
      subject { get('/') }
      it { should route_to("login#login") }
    end
  end
  
  describe 'login' do
    describe 'GET login' do
      subject { get('/login') }
      it { should route_to(controller: 'login', action: 'login') }
    end
    
    describe 'named route' do
      subject { get( login_path ) }
      it { should route_to(controller: 'login', action: 'login') }
    end

    describe 'POST login' do
      subject { post('/login') }
      it { should route_to(controller: 'login', action: 'do_login') }
    end

    describe 'named route' do
      subject { post( login_path ) }
      it { should route_to(controller: 'login', action: 'do_login') }
    end
  end

  describe "logout" do
    describe 'POST logout' do
      subject { post('/logout') }
      it { should route_to(controller: 'login', action: 'do_logout') }
    end

    describe 'named route' do
      subject { post(logout_path) }
      it { should route_to(controller: 'login', action: 'do_logout') }
    end
  end
  
  describe "reload_config" do
    describe 'GET reload_config' do
      subject { post('/reload_config') }
      it { should route_to(controller: 'main', action: 'reload_config') }
    end

    describe 'named route' do
      subject { post( reload_config_path ) }
      it { should route_to(controller: 'main', action: 'reload_config') }
    end
  end
  
  describe 'current...' do
    describe 'entries' do
      subject { { get: '/current/entries' }}
      it { should route_to(controller: 'entries', action: 'index') }
    end
    describe 'profit_losses' do
      subject { { get: '/current/profit_losses' }}
      it { should route_to(controller: 'profit_losses', action: 'index') }
    end

    describe '/current/balance_sheets' do
      subject { { get: '/current/balance_sheets' }}
      it { should route_to(controller: 'balance_sheets', action: 'index') }
    end


    describe 'named_route' do
      describe "entries" do
        subject { { get: current_entries_path }}
        it { should route_to(controller: 'entries', action: 'index') }
      end
    
      describe 'profit_losses' do
        subject { { get: current_profit_losses_path }}
        it { should route_to(controller: 'profit_losses', action: 'index') }
      end
      
      describe 'balance_sheets' do
        subject { { get: current_balance_sheets_path }}
        it { should route_to(controller: 'balance_sheets', action: 'index') }
      end
    end    
  end

  describe 'months/2000/3/..' do
    describe 'GET "entries"' do
      subject { { get: '/months/2008/3/entries' }}
      it { should route_to(controller: 'entries', action: 'index', year: "2008", month: "3") }
    end
    describe 'GET "profit_losses"' do
      subject { { get: '/months/2008/3/profit_losses' } }
      it { should route_to(controller: 'profit_losses', action: 'index', year: "2008", month: "3") }
    end

    describe 'GET "balance_sheets"' do
      subject { { get: '/months/2008/3/balance_sheets' } }
      it { should route_to(controller: 'balance_sheets', action: 'index', year: "2008", month: "3") }
    end
  end
  
  describe '/tags/:tag/..' do
    describe 'GET "entries"' do
      subject { { get: '/tags/hogehoge/entries' }}
      it { should route_to(controller: 'entries', action: 'index', tag: 'hogehoge')}
    end

    describe 'named route' do
      subject { { get: tag_entries_path('hogehoge') }}
      it { should route_to(controller: 'entries', action: 'index', tag: 'hogehoge')}
    end
  end

  describe '/marks/:mark/..' do
    describe 'GET "entries"' do
      subject { { get: '/marks/hogehoge/entries' }}
      it { should route_to(controller: 'entries', action: 'index', mark: 'hogehoge')}
    end

    describe 'named route' do
      subject { { get: mark_entries_path('hogehoge') }}
      it { should route_to(controller: 'entries', action: 'index', mark: 'hogehoge')}
    end
  end

  describe '/entries/10/confirmation_required' do
    subject { put("/entries/10/confirmation_required") }
    it { should route_to(controller: 'confirmation_requireds', action: 'update', entry_id: '10') }
  end

  describe 'account_status' do
    subject {get("/account_status") }
    it { should route_to("account_statuses#show") }
  end
  
  describe 'confirmation_status' do
    subject {get("/confirmation_status") }
    it { should route_to("confirmation_statuses#show") }
  end

  describe 'tag_status' do
    subject {get("/tag_status") }
    it { should route_to("tag_statuses#show") }
  end
  
  describe 'entry_candidates' do
    subject {get("/entry_candidates") }
    it { should route_to("entry_candidates#index") }
  end

  describe '/admin' do
    describe 'users' do
      subject { get("/admin/users") }
      it { should route_to("admin/users#index") }
    end
  end

  describe 'settings' do
    describe "accounts" do
      subject { get("/settings/accounts") }
      it {should route_to("settings/accounts#index") }
    end
    describe "credit_relations" do
      subject { get("/settings/credit_relations") }
      it {should route_to("settings/credit_relations#index") }
    end
    describe "user" do
      subject { get("/settings/user") }
      it {should route_to("settings/users#show") }
    end
  end

  describe "api" do
    describe "assets" do
      subject { get("/api/assets") }
      it {should route_to("api/assets#index") }
    end
    describe "budgets" do
      subject { get("/api/budgets") }
      it {should route_to("api/budgets#index") }
    end
    describe "yearly_assets" do
      subject { get("/api/yearly_assets") }
      it {should route_to("api/yearly_assets#index") }
    end
    describe "budgets" do
      subject { get("/api/yearly_budgets") }
      it {should route_to("api/yearly_budgets#index") }
    end
  end
end

