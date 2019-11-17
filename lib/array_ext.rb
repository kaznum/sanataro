# frozen_string_literal: true

module Sanataro
  module ArrayExt
    def to_custom_hash
      ret = []
      each do |a|
        ret << a.to_custom_hash
      end
      ret
    end
  end
end

Array.prepend Sanataro::ArrayExt
