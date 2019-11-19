# frozen_string_literal: true
require 'spec_helper'

describe ApplicationHelper, type: :helper do
  describe 'colored_account_name' do
    before do
      mock_user = mock_model(User)
      expect(mock_user).to receive(:all_accounts).at_least(:once).and_return(1 => '<SAMPLE', 2 => 'NOT COLORED>')
      expect(mock_user).to receive(:account_bgcolors).at_least(:once).and_return(1 => '123456')
      assign(:user, mock_user)
    end

    describe 'colored' do
      subject { helper.colored_account_name(1) }
      it { is_expected.to eq("<span class='label' style='background-color: #123456;'>&lt;SAMPLE</span>".html_safe) }
    end
    describe 'not colored' do
      subject { helper.colored_account_name(2) }
      it { is_expected.to eq('NOT COLORED&gt;'.html_safe) }
    end
  end

  describe 'calendar_from' do
    fixtures :users, :monthly_profit_losses
    context 'when there are monthly_profit_losses records,' do
      before do
        @min_month = MonthlyProfitLoss.where(user_id: users(:user1).id).where('amount <> 0').minimum(:month)
      end

      subject { helper.calendar_from(users(:user1)) }
      it { is_expected.to eq(@min_month.beginning_of_month.months_ago(2).beginning_of_month) }
    end

    context 'when there is no monthly_profit_losses record,' do
      before do
        MonthlyProfitLoss.destroy_all
      end

      subject { helper.calendar_from(users(:user1)) }
      it { is_expected.to eq(Date.today.beginning_of_month.months_ago(2).beginning_of_month) }
    end
  end

  describe 'calendar_to' do
    fixtures :users, :monthly_profit_losses
    context 'when there are monthly_profit_losses records,' do
      before do
        @max_month = MonthlyProfitLoss.where(user_id: users(:user1).id).where('amount <> 0').maximum(:month)
      end

      subject { helper.calendar_to(users(:user1)) }
      it { is_expected.to eq(@max_month.beginning_of_month.months_since(2).beginning_of_month) }
    end

    context 'when there is no monthly_profit_losses record,' do
      before do
        MonthlyProfitLoss.destroy_all
      end

      subject { helper.calendar_to(users(:user1)) }
      it { is_expected.to eq(Date.today.beginning_of_month.months_since(2).beginning_of_month) }
    end
  end

  describe '#highlight' do
    subject { helper.highlight('#hello') }
    it { is_expected.to eq("$('#hello').effect('highlight', {color: '#{GlobalSettings.effect.highlight.color}'}, #{GlobalSettings.effect.highlight.duration});") }
  end

  describe '#fadeout_and_remove' do
    subject { helper.fadeout_and_remove('#hello') }
    it { is_expected.to eq("$('#hello').fadeOut(#{GlobalSettings.effect.fade.duration}, function() {$('#hello').remove();});") }
  end

  describe '#today' do
    subject { helper.today }
    it { is_expected.to eq(Date.today) }
  end
end
