# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

ならば /^"([^"]*)"ページにリダイレクトすること$/ do |page_name|
  path = URI.parse(current_url).path
  begin
    timeout(Capybara.default_wait_time) do
      while(path != path_to(page_name)) do
        sleep 0.1
        path = URI.parse(current_url).path
      end
    end
  rescue TimeoutError
    # do nothing
  end

  if path.respond_to? :should
    path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), path
  end
end

