# frozen_string_literal: true

class GlobalSettings < Settingslogic
  source File.join(Rails.root, 'config', 'application.yml')
  namespace Rails.env
end
