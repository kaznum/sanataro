require 'spec_helper'

describe :routes, :type => :routing do

  describe "root" do
    describe 'GET /' do
      subject { get('/') }
      it { is_expected.to route_to("login#login") }
    end
  end

  describe 'login' do
    describe 'GET login' do
      subject { get('/login') }
      it { is_expected.to route_to(controller: 'login', action: 'login') }
    end

    describe 'named route' do
      subject { get(login_path) }
      it { is_expected.to route_to(controller: 'login', action: 'login') }
    end

    describe 'POST login' do
      subject { post('/login') }
      it { is_expected.to route_to(controller: 'login', action: 'do_login') }
    end

    describe 'named route' do
      subject { post(login_path) }
      it { is_expected.to route_to(controller: 'login', action: 'do_login') }
    end
  end

  describe "logout" do
    describe 'POST logout' do
      subject { post('/logout') }
      it { is_expected.to route_to(controller: 'login', action: 'do_logout') }
    end

    describe 'named route' do
      subject { post(logout_path) }
      it { is_expected.to route_to(controller: 'login', action: 'do_logout') }
    end
  end

  describe "create_user" do
    describe 'GET create_user' do
      subject { get('/create_user') }
      it { is_expected.to route_to("login#create_user") }
    end

    describe 'named route' do
      subject { get(create_user_path) }
      it { is_expected.to route_to("login#create_user") }
    end

    describe 'POST create_user' do
      subject { post('/create_user') }
      it { is_expected.to route_to("login#do_create_user") }
    end

    describe 'named route' do
      subject { post(create_user_path) }
      it { is_expected.to route_to("login#do_create_user") }
    end
  end

  describe "login#confirmation" do
    describe 'GET confirm_user' do
      subject { get('/confirm_user') }
      it { is_expected.to route_to("login#confirmation") }
    end

    describe 'named route' do
      subject { get(confirm_user_path) }
      it { is_expected.to route_to("login#confirmation") }
    end
  end

  describe 'current...' do
    %w(entries profit_losses balance_sheets).each do |controller|
      describe "get /current/#{controller}" do
        subject { get("/current/#{controller}") }
        it { is_expected.to route_to("#{controller}#index") }
      end
      describe "post /current/#{controller}" do
        subject { post("/current/#{controller}") }
        it { is_expected.to route_to("#{controller}#create") }
      end
      describe "get /current/#{controller}/10" do
        subject { get("/current/#{controller}/10") }
        it { is_expected.to route_to("#{controller}#show", id: "10") }
      end
      describe "put /current/#{controller}/10" do
        subject { put("/current/#{controller}/10") }
        it { is_expected.to route_to("#{controller}#update", id: "10") }
      end

      describe "delete /current/#{controller}/10" do
        subject { delete("/current/#{controller}/10") }
        it { is_expected.to route_to("#{controller}#destroy", id: "10") }
      end

      describe "get /current/#{controller}/10/edit" do
        subject { get("/current/#{controller}/10/edit") }
        it { is_expected.to route_to("#{controller}#edit", id: "10") }
      end
    end

    describe 'named_route' do
      describe "entries" do
        subject { { get: current_entries_path }}
        it { is_expected.to route_to(controller: 'entries', action: 'index') }
      end

      describe 'profit_losses' do
        subject { { get: current_profit_losses_path }}
        it { is_expected.to route_to(controller: 'profit_losses', action: 'index') }
      end

      describe 'balance_sheets' do
        subject { { get: current_balance_sheets_path }}
        it { is_expected.to route_to(controller: 'balance_sheets', action: 'index') }
      end
    end
  end

  describe 'months/2000/3/..' do
    describe 'GET "entries"' do
      subject { { get: '/months/2008/3/entries' }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', year: "2008", month: "3") }
    end
    describe 'GET "profit_losses"' do
      subject { { get: '/months/2008/3/profit_losses' } }
      it { is_expected.to route_to(controller: 'profit_losses', action: 'index', year: "2008", month: "3") }
    end

    describe 'GET "balance_sheets"' do
      subject { { get: '/months/2008/3/balance_sheets' } }
      it { is_expected.to route_to(controller: 'balance_sheets', action: 'index', year: "2008", month: "3") }
    end
  end

  describe '/tags/:tag/..' do
    describe 'GET "entries"' do
      subject { { get: '/tags/hogehoge/entries' }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', tag: 'hogehoge') }
    end

    describe 'named route' do
      subject { { get: tag_entries_path('hogehoge') }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', tag: 'hogehoge') }
    end
  end

  describe '/tags/:tag/entries/:entry_id/confirmation_required' do
    describe 'PUT "confirmation_required"' do
      subject { { put: '/tags/hogehoge/entries/10/confirmation_required' }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', tag: 'hogehoge', entry_id: '10') }
    end

    describe 'named route' do
      subject { { put: tag_entry_confirmation_required_path('hogehoge', 10) }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', tag: 'hogehoge', entry_id: '10') }
    end
  end

  describe "/marks/:mark/.." do
    describe 'GET "entries"' do
      subject { { get: '/marks/hogehoge/entries' }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', mark: 'hogehoge') }
    end

    describe 'named route' do
      subject { { get: mark_entries_path('hogehoge') }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', mark: 'hogehoge') }
    end
  end

  describe '/marks/:mark/entries/:entry_id/confirmation_required' do
    describe 'PUT "confirmation_required"' do
      subject { { put: '/marks/hogehoge/entries/10/confirmation_required' }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', mark: 'hogehoge', entry_id: '10') }
    end

    describe 'named route' do
      subject { { put: mark_entry_confirmation_required_path('hogehoge', 10) }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', mark: 'hogehoge', entry_id: '10') }
    end
  end

  describe "/keywords/:keyword/.." do
    describe 'GET "entries"' do
      subject { { get: '/keywords/hogehoge/entries' }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', keyword: 'hogehoge') }
    end

    describe 'named route' do
      subject { { get: keyword_entries_path('hogehoge') }}
      it { is_expected.to route_to(controller: 'entries', action: 'index', keyword: 'hogehoge') }
    end
  end

  describe '/keywords/:keyword/entries/:entry_id/confirmation_required' do
    describe 'PUT "confirmation_required"' do
      subject { { put: '/keywords/hogehoge/entries/10/confirmation_required' }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', keyword: 'hogehoge', entry_id: '10') }
    end

    describe 'named route' do
      subject { { put: keyword_entry_confirmation_required_path('hogehoge', 10) }}
      it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', keyword: 'hogehoge', entry_id: '10') }
    end
  end

  describe '/entries/10/confirmation_required' do
    subject { put("/entries/10/confirmation_required") }
    it { is_expected.to route_to(controller: 'confirmation_requireds', action: 'update', entry_id: '10') }
  end

  %w(account_status confirmation_status tag_status).each do |controller|
    describe "get #{controller}" do
      subject { get("/#{controller}") }
      it { is_expected.to route_to("#{controller.pluralize}#show") }
    end
    describe "destroy #{controller}" do
      subject { delete("/#{controller}") }
      it { is_expected.to route_to("#{controller.pluralize}#destroy") }
    end
  end

  describe 'entry_candidates' do
    subject { get("/entry_candidates") }
    it { is_expected.to route_to("entry_candidates#index") }
  end

  describe '/admin' do
    describe 'users' do
      subject { get("/admin/users") }
      it { is_expected.to route_to("admin/users#index") }
    end
  end

  describe 'settings' do
    %w(accounts credit_relations).each do |controller|
      describe "get #{controller}" do
        subject { get("/settings/#{controller}") }
        it { is_expected.to route_to("settings/#{controller}#index") }
      end
      describe "post #{controller}" do
        subject { post("/settings/#{controller}") }
        it { is_expected.to route_to("settings/#{controller}#create") }
      end
      describe "get #{controller}/10" do
        subject { get("/settings/#{controller}/10") }
        it { is_expected.to route_to("settings/#{controller}#show", id: "10") }
      end
      describe "put #{controller}/10" do
        subject { put("/settings/#{controller}/10") }
        it { is_expected.to route_to("settings/#{controller}#update", id: "10") }
      end
      describe "delete #{controller}/10" do
        subject { delete("/settings/#{controller}/10") }
        it { is_expected.to route_to("settings/#{controller}#destroy", id: "10") }
      end
      describe "get #{controller}/10/edit" do
        subject { get("/settings/#{controller}/10/edit") }
        it { is_expected.to route_to("settings/#{controller}#edit", id: "10") }
      end
    end

    describe "user" do
      describe "get" do
        subject { get("/settings/user") }
        it { is_expected.to route_to("settings/users#show") }
      end
      describe "put" do
        subject { put("/settings/user") }
        it { is_expected.to route_to("settings/users#update") }
      end
    end
  end

  describe "api" do
    describe "sessions" do
      describe "create api/session" do
        subject { post("/api/session") }
        it { is_expected.to route_to("api/sessions#create") }
      end

      describe "destroy api/session" do
        subject { delete("/api/session") }
        it { is_expected.to route_to("api/sessions#destroy") }
      end
    end

    %w(entries accounts).each do |controller|
      describe "get api/#{controller}" do
        subject { get("/api/#{controller}") }
        it { is_expected.to route_to("api/#{controller}#index") }
      end
      describe "get api/#{controller}/10" do
        subject { get("/api/#{controller}/10") }
        it { is_expected.to route_to("api/#{controller}#show", id: "10") }
      end
      describe "get api/#{controller}/10/edit" do
        subject { get("/api/#{controller}/10/edit") }
        it { is_expected.to route_to("api/#{controller}#edit", id: "10") }
      end
      describe "put api/#{controller}/10" do
        subject { put("/api/#{controller}/10") }
        it { is_expected.to route_to("api/#{controller}#update", id: "10") }
      end
      describe "delete api/#{controller}/10" do
        subject { delete("/api/#{controller}/10") }
        it { is_expected.to route_to("api/#{controller}#destroy", id: "10") }
      end
      describe "post api/#{controller}" do
        subject { post("/api/#{controller}") }
        it { is_expected.to route_to("api/#{controller}#create") }
      end
    end
  end

  describe "chart_data" do

    %w(assets budgets yearly_assets yearly_budgets).each do |controller|
      describe "get chart_data/#{controller}" do
        subject { get("/chart_data/#{controller}") }
        it { is_expected.to route_to("chart_data/#{controller}#index") }
      end
      describe "get chart_data/#{controller}/10" do
        subject { get("/chart_data/#{controller}/10") }
        it { is_expected.to route_to("chart_data/#{controller}#show", id: "10") }
      end
      describe "get chart_data/#{controller}/10/edit" do
        subject { get("/chart_data/#{controller}/10/edit") }
        it { is_expected.to route_to("chart_data/#{controller}#edit", id: "10") }
      end
      describe "put chart_data/#{controller}/10" do
        subject { put("/chart_data/#{controller}/10") }
        it { is_expected.to route_to("chart_data/#{controller}#update", id: "10") }
      end
      describe "delete chart_data/#{controller}/10" do
        subject { delete("/chart_data/#{controller}/10") }
        it { is_expected.to route_to("chart_data/#{controller}#destroy", id: "10") }
      end
      describe "post chart_data/#{controller}" do
        subject { post("/chart_data/#{controller}") }
        it { is_expected.to route_to("chart_data/#{controller}#create") }
      end
    end
  end
end
