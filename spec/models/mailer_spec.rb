# frozen_string_literal: true

require 'spec_helper'

describe Mailer, type: :model do
  describe 'signup_confirmation' do
    let(:user) { mock_model(User, email: 'foo@example.com', login: 'userhogehoge', confirmation: 'AABBCCDD') }
    let(:mail) { Mailer.signup_confirmation(user) }

    describe 'mail' do
      subject { mail }

      describe '#subject' do
        subject { super().subject }
        it { is_expected.to eq("[#{GlobalSettings.product_name}] ユーザ登録は完了していません") }
      end

      describe '#to' do
        subject { super().to }
        it { is_expected.to eq([user.email]) }
      end

      describe '#from' do
        subject { super().from }
        it { is_expected.to eq([GlobalSettings.system_mail_address]) }
      end
    end

    describe 'user' do
      subject { mail.body.encoded }
      it { is_expected.to match(user.login) }
    end
  end

  describe 'signup_complete' do
    let(:user) { mock_model(User, email: 'foo@example.com', login: 'userhogehoge', confirmation: 'AABBCCDD') }
    let(:mail) { Mailer.signup_complete(user) }

    describe 'mail' do
      subject { mail }

      describe '#subject' do
        subject { super().subject }
        it { is_expected.to eq("[#{GlobalSettings.product_name}] ユーザ登録完了") }
      end

      describe '#to' do
        subject { super().to }
        it { is_expected.to eq([user.email]) }
      end

      describe '#from' do
        subject { super().from }
        it { is_expected.to eq([GlobalSettings.system_mail_address]) }
      end
    end

    describe 'user' do
      subject { mail.body.encoded }
      it { is_expected.to match(user.login) }
    end
  end
end
