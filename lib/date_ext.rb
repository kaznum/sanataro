module Sanataro::DateExt
  def to_milliseconds
    to_time.to_i * 1000
  end
end
Date.send(:include, Sanataro::DateExt)
