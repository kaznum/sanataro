# -*- coding: utf-8 -*-
module StringDecorator
  class << self
    def emolettise(str)
      str = str.html_safe? ? str : (ERB::Util.html_escape str)
      str.gsub(/(\(|（)(笑|爆|嬉|喜|楽|驚|泣|涙|悲|怒|厳|辛|苦|閃|汗|忙|急|輝)(\)|）)/) { |s|
        "<span class='emo'>#{s}</span>"
      }.html_safe
    end
  end
end

class String
  # To use this method, add gem 'rails_emoji' in Gemfile
  def decorate
    self.emolettise.emojify.html_safe
  end

  def emolettise
    StringDecorator.emolettise(self)
  end
end
