# -*- coding: utf-8 -*-
module EmolettHelper
  def emolettise(str)
    str.gsub(/(\(|（)(笑|爆|嬉|喜|楽|驚|泣|涙|悲|怒|厳|辛|苦|閃|汗|忙|急|輝)(\)|）)/) { |s|
      "<span class='emo'>#{s}</span>"
    }.html_safe
  end
end

