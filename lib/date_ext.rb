# frozen_string_literal: true

module Sanataro
  module DateExt
    def to_milliseconds
      to_time.to_i * 1000
    end
  end
end

Date.prepend Sanataro::DateExt
