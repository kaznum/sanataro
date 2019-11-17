require 'spec_helper'

describe Settings::CreditRelationsHelper, :type => :helper do
  describe 'this month' do
    subject { helper.localize_relative_month(0) }
    it { is_expected.to eq(I18n.t('settings.credit_relations.same_month')) }
  end

  describe 'next month' do
    subject { helper.localize_relative_month(1) }
    it { is_expected.to eq(I18n.t('settings.credit_relations.next_month')) }
  end

  describe 'the month after next month' do
    subject { helper.localize_relative_month(2) }
    it { is_expected.to eq(I18n.t('settings.credit_relations.month_after_next')) }
  end

  describe 'three month later' do
    subject { helper.localize_relative_month(3) }
    it { is_expected.to eq(I18n.t('settings.credit_relations.two_month_after_next')) }
  end
end
