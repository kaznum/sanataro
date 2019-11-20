# frozen_string_literal: true

require 'spec_helper'

describe CommonUtil do
  describe 'remove_comma' do
    context 'no comma' do
      subject { CommonUtil.remove_comma('120030') }
      it { is_expected.to eq '120030' }
    end

    context 'valid comma' do
      subject { CommonUtil.remove_comma('120,030') }
      it { is_expected.to eq '120030' }
    end

    context 'invalid comma' do
      subject { CommonUtil.remove_comma(',1,20,030') }
      it { is_expected.to eq '120030' }
    end

    context 'param is nil' do
      subject { CommonUtil.remove_comma(nil) }
      it { is_expected.to be_nil }
    end
  end

  describe '#correct_password?' do
    context 'when with valid_password,' do
      subject { CommonUtil.correct_password?('hello', Digest::SHA1.hexdigest('hello')) }
      it { is_expected.to be_truthy }
    end

    context 'when plain str is nil,' do
      subject { CommonUtil.correct_password?(nil, nil) }
      it { is_expected.to be_falsey }
    end

    context 'when hex str is nil,' do
      subject { CommonUtil.correct_password?(nil, nil) }
      it { is_expected.to be_falsey }
    end
  end

  describe '#crypt' do
    subject { CommonUtil.crypt('hello') }
    it { is_expected.to eq Digest::SHA1.hexdigest('hello') }
  end
end
