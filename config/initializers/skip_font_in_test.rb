# for capybara-webkit and font awesome problem
if Rails.env.test?
  Rails.application.config.assets.paths.reject! { |path| path.to_s =~ /fonts/ }
end

