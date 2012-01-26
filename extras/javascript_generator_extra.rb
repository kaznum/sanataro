# -*- coding: utf-8 -*-
class ActionView::Helpers::PrototypeHelper::JavaScriptGenerator
  def fadeout_and_remove(selector)
    # 表示されていない可能性があるため、Collection Proxyを利用する
    self.select(selector).each do |etty|
      etty.visual_effect :fade, :duration => FADE_DURATION
    end
    self.select(selector).each do |etty|
      self.delay(3.seconds) do
        etty.remove
      end
    end
  end

  def hightlight(selector)
    self.select(s).each do |etty|
      etty.visual_effect :highlight, :duration => HIGHLIGHT_DURATION
    end
  end
  
end
