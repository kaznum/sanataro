# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'paths'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'selectors'))

前提 /^収支入力ページを表示している$/ do
  step %{I am on ログイン}
  step %{I fill in "login" with "user1"}
  step %{I fill in "password" with "123456"}
  step %{I press "ログイン"}
  find('#input_item_area')
end

前提 /^(.+)年(.+)月の収支入力ページを表示している$/ do |year, month|
  step %{I am on ログイン}
  step %{I fill in "login" with "user1"}
  step %{I fill in "password" with "123456"}
  step %{I press "ログイン"}
  find('#input_item_area')
  step %{I am on #{year}年#{month}月の収支入力}
end

前提 /^残高調整登録ページを表示している$/ do
  step %{I am on ログイン}
  step %{I fill in "login" with "user1"}
  step %{I fill in "password" with "123456"}
  step %{I press "ログイン"}
  find('#input_item_area')
  step %{I follow "残高調整の登録"}
  find('#input_item_area #entry_adjustment_amount')
end

前提 /^(.+)年(.+)月の残高調整登録ページを表示している$/ do |year, month|
  step %{I am on ログイン}
  step %{I fill in "login" with "user1"}
  step %{I fill in "password" with "123456"}
  step %{I press "ログイン"}
  find('#input_item_area')
  step %{I am on #{year}年#{month}月の収支入力}
  step %{I follow "残高調整の登録"}
  find('#input_item_area #entry_adjustment_amount')
end
