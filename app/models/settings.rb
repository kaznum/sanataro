class Settings < Settingslogic
  source File.join(Rails.root, "config", "application.yml")
  namespace Rails.env
end
