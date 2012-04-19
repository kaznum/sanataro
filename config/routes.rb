Kakeibo3::Application.routes.draw do
  root :to => "login#login"

  match 'simple', :to => 'entries#new', :entry_type => 'simple', :as => 'simple_input'
  match 'login' => 'login#login', :as => :login, :via => :get
  match 'login' => 'login#do_login', :as => :login, :via => :post
  match 'logout' => 'login#do_logout', :as => :logout
  match 'create_user' => 'login#create_user', :as => :create_user, :via => :get
  match 'create_user' => 'login#do_create_user', :as => :create_user, :via => :post
  match 'confirm_user' => 'login#confirmation', :as => :confirm_user, :via => :get
  match 'reload_config' => 'main#reload_config', :as => :reload_config
  match 'show_parent_child_item' => "main#show_parent_child_item", :as => :show_parent_child_item, :via => :get

  scope 'months/:year/:month' do
    resources :entries
    resources :profit_losses
    resources :balance_sheets
  end

  scope 'current' do
    resources :entries, :as => 'current_entries'
    resources :profit_losses, :as => 'current_profit_losses'
    resources :balance_sheets, :as => 'current_balance_sheets'
  end

  %w( tag mark ).each do |s|
    scope "/#{s.pluralize}/:#{s}", as: s.to_sym do
      resources :entries do
        resource :confirmation_required
      end
    end
  end

  resources :entries do
    resource :confirmation_required
  end

  resource :account_status
  resource :confirmation_status
  resource :tag_status
  resources :entry_candidates
  namespace(:admin) do
    resources :users
  end

  namespace(:settings) do
    resources :accounts
    resources :credit_relations
    resource :user
  end

  namespace(:api) do
    resources :assets
    resources :budgets
    resources :yearly_budgets
    resources :yearly_assets
  end
end

