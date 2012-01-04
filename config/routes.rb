Kakeibo3::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "login#login"

  match 'simple', :to => 'entries#new', :entry_type => 'simple', :as => 'simple_input'
#  map.signup '/signup', :controller => 'login', :action => 'create_user'
#  map.signupconfirmation '/signupconfirmation/:login/:sid', :controller => 'login', :action => 'confirmation'
  #  map.login '/login', :controller => 'login', :action => 'login'
  match 'login' => 'login#login', :as => :login
  #  map.logout '/logout', :controller => 'login', :action => 'do_logout'
  match 'logout' => 'login#do_logout', :as => :logout
  
  #  month_base = '/months/:year/:month'
  #  resources :entries, :path_prefix => month_base
  #  resources :profit_losses, :path_prefix => month_base
  #  resources :balance_sheets, :path_prefix => month_base
  scope 'months/:year/:month' do
    resources :entries
    resources :profit_losses
    resources :balance_sheets
  end


#  resources :entries, :path_prefix => 'current', :name_prefix => 'current_'
  resources :entries, :path_prefix => 'current', :as => 'current_entries'
#  resources :profit_losses, :path_prefix => 'current', :name_prefix => 'current_'
  resources :profit_losses, :path_prefix => 'current',:as => 'current_profit_losses'
#  resources :balance_sheets, :path_prefix => 'current', :name_prefix => 'current_'
  resources :balance_sheets, :path_prefix => 'current', :as => 'current_balance_sheets'
  
  tag_base = '/tags/:tag'
#  resources :entries, :path_prefix => tag_base, :name_prefix => 'tag_'
  resources :entries, :path_prefix => tag_base, :as => 'tag_entries'
  mark_base = '/marks/:mark'
#  resources :entries, :path_prefix => mark_base, :name_prefix => 'mark_'
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

    
#  map.resources :users, :controller => 'admin/users', :name_prefix => 'admin_', :path_prefix => '/admin'
  namespace(:settings) do
    resources :accounts
    resources :credit_relations
    resource :user
  end
#  map.resources :accounts, :controller => 'settings/accounts', :name_prefix => 'settings_', :path_prefix => '/settings'

  # See how all your routes lay out with "rake routes"

  namespace(:api) do
    resources :assets
    resources :budgets
    scope ':year_month' do
      resources :entries
    end
  end
  
  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
end

