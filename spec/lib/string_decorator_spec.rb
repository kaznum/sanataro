# frozen_string_literal: true
require 'spec_helper'

describe StringDecorator do
  describe 'String#emolettise' do
    context 'when string is already escaped, ' do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc".html_safe.emolettise }
      it { is_expected.to eq("aaa<a href='aa'>bbb</a><span class='emo'>(笑)</span>ccc") }
      it { is_expected.to be_html_safe }
    end

    context 'when string is not escaped yet, ' do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc".emolettise }
      it { is_expected.to eq("aaa&lt;a href=&#39;aa&#39;&gt;bbb&lt;/a&gt;<span class='emo'>(笑)</span>ccc") }
      it { is_expected.to be_html_safe }
    end
  end

  describe 'String#decorate' do
    context 'when string is already escaped, ' do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc:sushi:ddd".html_safe.decorate }
      it { is_expected.to match %r(aaa<a href='aa'>bbb</a><span class='emo'>\(笑\)</span>ccc<img src=[^>]+>ddd) }
      it { is_expected.to be_html_safe }
    end

    context 'when string is not escaped yet, ' do
      subject { "aaa<a href='aa'>bbb</a>(笑)ccc:sushi:ddd".decorate }
      it { is_expected.to match %r(aaa&lt;a href=&#39;aa&#39;&gt;bbb&lt;/a&gt;\<span class='emo'\>\(笑\)\</span\>ccc\<img src=[^>]+\>ddd) }
      it { is_expected.to be_html_safe }
    end
  end
end
