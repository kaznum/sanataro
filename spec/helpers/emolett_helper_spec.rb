# -*- coding: utf-8 -*-
require 'spec_helper'

describe EmolettHelper do
  context "when a emolett exists," do
    subject { helper.emolettise("あいうえお(笑)かきくけこ") }
    it { should == "あいうえお<span class='emo'>(笑)</span>かきくけこ" }
  end

  context "when multiple emoletts exist," do
    subject { helper.emolettise("あいう(泣)えお(笑)かきくけこ") }
    it { should == "あいう<span class='emo'>(泣)</span>えお<span class='emo'>(笑)</span>かきくけこ" }
  end

  context "when multibyte parentheses are used," do
    subject { helper.emolettise("あいう（泣）えお") }
    it { should == "あいう<span class='emo'>（泣）</span>えお" }
  end
end
