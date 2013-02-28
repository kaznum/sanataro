module Sanataro::ArrayExt
  def to_custom_hash
    ret = []
    self.each do |a|
      ret << a.to_custom_hash
    end
    ret
  end
end
Array.send(:include, Sanataro::ArrayExt)
