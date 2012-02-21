# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

前提 /^収支入力ページを表示している$/ do
  step %{I am on 収支入力}
  step %{I fill in "login" with "user1"}
  step %{I fill in "password" with "123456"}
  step %{I press "ログイン"}
  find('p#add_item_explain')
end


