# Be sure to restart your server when you modify this file.

#Kakeibo3::Application.config.session_store :cookie_store, :key => '_kakeibo3_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Kakeibo3::Application.config.session_store :active_record_store

Kakeibo3::Application.config.session = {
  :key         => '_kakeibo',
  :secret      => 'a7a61b4a00d36e4285694dbd04e6841057f4f2457945a32c7a998975f9443cbee019dbe34af535b3812852152c090ce7c71941cb124b6c91d70e5b6c136a97b9'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
Kakeibo3::Application.config.session_store = :active_record_store

