# -*- coding: utf-8 -*-
require 'spec_helper'

describe CommonUtil do
  describe "remove_comma" do
    context "no comma" do
      subject { CommonUtil.remove_comma("120030") }
      it { should eq "120030" }
    end

    context "valid comma" do
      subject { CommonUtil.remove_comma("120,030") }
      it { should eq "120030" }
    end

    context "invalid comma" do
      subject { CommonUtil.remove_comma(",1,20,030") }
      it { should eq "120030" }
    end

    context "param is nil" do
      subject { CommonUtil.remove_comma(nil) }
      it { should be_nil }
    end
  end

  describe "#correct_password?" do
    context "when with valid_password," do
      subject { CommonUtil.correct_password?("hello", Digest::SHA1.hexdigest("hello")) }
      it { should be_true }
    end

    context "when plain str is nil," do
      subject { CommonUtil.correct_password?(nil, nil) }
      it { should be_false }
    end

    context "when hex str is nil," do
      subject { CommonUtil.correct_password?(nil, nil) }
      it { should be_false }
    end
  end

  describe "#crypt" do
    subject { CommonUtil.crypt("hello") }
    it { should eq Digest::SHA1.hexdigest("hello") }
  end
end
