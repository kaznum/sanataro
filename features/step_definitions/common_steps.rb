# encoding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'paths'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'support', 'selectors'))

ならば /^"([^"]*)"ページにリダイレクトすること$/ do |page_name|
  path = URI.parse(current_url).path
  begin
    Timeout.timeout(Capybara.default_max_wait_time) do
      while(path != path_to(page_name)) do
        sleep 0.1
        path = URI.parse(current_url).path
      end

      if path.respond_to? :should
        path.should == path_to(page_name)
      else
        assert_equal path_to(page_name), path
      end
    end
  rescue TimeoutError
    assert(false, "'#{page_name}'ページにリダイレクトしませんでした。")
  end
end

