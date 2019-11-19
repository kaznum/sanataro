# frozen_string_literal: true
# https://github.com/cucumber/cucumber/issues/423
# Why: http://groups.google.com/group/cukes/browse_thread/thread/5682d41436e235d7

if Rails.env.test?
  require 'minitest/unit'
  # Don't attempt to monkeypatch if the require succeeded but didn't
  # define the actual module.
  #
  # https://github.com/cucumber/cucumber/pull/93
  # http://youtrack.jetbrains.net/issue/TW-17414
  if defined?(MiniTest::Unit)
    class MiniTest::Unit
      class << self
        @@installed_at_exit = true
      end

      def run(*)
        0
      end
    end
  end
end
