# Be sure to restart your server when you modify this file.

#Sanataro::Application.config.session_store :cookie_store, :key => '_sanataro_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Sanataro::Application.config.session_store :active_record_store

Sanataro::Application.config.session = {
  :key         => '_sanataro',
  :secret      => 'a7a61b4a00d36e4285694dbd04e6841057f4f2457945a32c7a998975f9443cbee019dbe34af535b3812852152c090ce7c71941cb124b6c91d70e5b6c136a97b9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
Sanataro::Application.config.session_store = :active_record_store
# Sanataro::Application.config.session_store = :memory_store
# Sanataro::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 60.minutes

