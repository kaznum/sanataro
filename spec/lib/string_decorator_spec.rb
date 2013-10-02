# -*- coding: utf-8 -*-
require 'spec_helper'

describe StringDecorator do
  describe "String#emolettise" do
    context "when string is already escaped, " do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc".html_safe.emolettise }
      it { should == "aaa<a href='aa'>bbb</a><span class='emo'>(笑)</span>ccc" }
      it { should be_html_safe }
    end

    context "when string is not escaped yet, " do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc".emolettise }
      it { should == "aaa&lt;a href=&#39;aa&#39;&gt;bbb&lt;/a&gt;<span class='emo'>(笑)</span>ccc" }
      it { should be_html_safe }
    end
  end

  describe "String#decorate" do
    context "when string is already escaped, " do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc:sushi:ddd".html_safe.decorate }
      it { should match %r(aaa<a href='aa'>bbb</a><span class='emo'>\(笑\)</span>ccc<img src=[^>]+>ddd) }
      it { should be_html_safe }
    end

    context "when string is not escaped yet, " do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc:sushi:ddd".decorate }
      it { should match %r(aaa&lt;a href=&#39;aa&#39;&gt;bbb&lt;/a&gt;\<span class='emo'\>\(笑\)\</span\>ccc\<img src=[^>]+\>ddd) }
      it { should be_html_safe }
    end
  end
end
