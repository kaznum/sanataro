# -*- coding: utf-8 -*-
require 'spec_helper'

describe EmolettHelper do
  subject { helper.emolettise("あいうえお(笑)かきくけこ") }
  it { should == "あいうえお<span class='emo'>(笑)</span>かきくけこ" }
end

