# frozen_string_literal: true

module StringDecorator
  class << self
    def emolettise(str)
      safe_str = str.html_safe? ? str : ERB::Util.html_escape(str)
      safe_str.gsub(/(\(|（)(笑|爆|嬉|喜|楽|驚|泣|涙|悲|怒|厳|辛|苦|閃|汗|忙|急|輝)(\)|）)/) do |s|
        "<span class='emo'>#{s}</span>"
      end.html_safe
    end
  end
end

class String
  # To use this method, add gem 'rails_emoji' in Gemfile
  def decorate
    emolettise.emojify.html_safe
  end

  def emolettise
    StringDecorator.emolettise(self)
  end
end
