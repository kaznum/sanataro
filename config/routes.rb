Kakeibo3::Application.routes.draw do
  root :to => "login#login"

  match 'simple', :to => 'entries#new', :entry_type => 'simple', :as => 'simple_input'
  match 'login' => 'login#login', :as => :login
  match 'logout' => 'login#do_logout', :as => :logout
  
  scope 'months/:year/:month' do
    resources :entries
    resources :profit_losses
    resources :balance_sheets
  end

  resources :entries, :path_prefix => 'current', :as => 'current_entries'
  resources :profit_losses, :path_prefix => 'current',:as => 'current_profit_losses'
  resources :balance_sheets, :path_prefix => 'current', :as => 'current_balance_sheets'
  
  tag_base = '/tags/:tag'
  resources :entries, :path_prefix => tag_base, :as => 'tag_entries'

  mark_base = '/marks/:mark'
  resources :entries, :path_prefix => mark_base, :as => 'mark_entries'

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
    scope ':year_month' do
      resources :entries
    end
  end
  
  match ':controller(/:action(/:id(.:format)))'
end

