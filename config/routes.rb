Sanataro::Application.routes.draw do
  use_doorkeeper

  root to: "login#login"

  match 'simple', to: 'entries#new', entry_type: 'simple', as: 'simple_input', via: :get
  resource(:login, path: 'login', as: 'login', controller: 'login', only: [:login, :do_login]) do
    get '/', action: 'login', on: :member
    post '/', action: 'do_login', on: :member
  end
  match 'logout' => 'login#do_logout', as: :logout, via: [:get, :post]
  resource(:create_user, path: 'create_user', as: 'create_user', controller: 'login', only: [:create_user, :do_create_user]) do
    get '/', action: 'create_user', on: :member
    post '/', action: 'do_create_user', on: :member
  end
  match 'confirm_user' => 'login#confirmation', as: :confirm_user, via: :get

  scope 'months/:year/:month' do
    resources :entries
    resources :profit_losses
    resources :balance_sheets
  end

  scope 'current' do
    resources :entries, as: 'current_entries'
    resources :profit_losses, as: 'current_profit_losses'
    resources :balance_sheets, as: 'current_balance_sheets'
  end

  %w( tag mark keyword ).each do |s|
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
    resources :entries
    resources :accounts
    resource :session
  end

  namespace(:chart_data) do
    resources :assets
    resources :budgets
    resources :yearly_budgets
    resources :yearly_assets
  end

  resources :emojis
end
