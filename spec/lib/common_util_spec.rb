# -*- coding: utf-8 -*-
require 'spec_helper'

describe CommonUtil do
  describe "self.separate_by_comma" do
    context "6 digit" do 
      subject { CommonUtil.separate_by_comma(120030) }
      it { should eq "120,030" }
    end

    context "3 digit" do 
      subject { CommonUtil.separate_by_comma(330) }
      it { should eq "330" }
    end

    context "7 digit" do 
      subject { CommonUtil.separate_by_comma(1234567) }
      it { should eq "1,234,567" }
    end

    context "7 digit < 0" do 
      subject { CommonUtil.separate_by_comma(-1234567) }
      it { should eq "-1,234,567" }
    end
    
    context "6 digit < 0" do 
      subject { CommonUtil.separate_by_comma(-120030) }
      it { should eq "-120,030" }
    end
  end

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

  describe "check_password" do
    context "valid_password" do
      subject { CommonUtil.check_password("hello", Digest::SHA1.hexdigest("hello"))}
      it { should be_true }
    end

    context "plain str is nil" do
      subject { CommonUtil.check_password(nil, nil)}
      it { should be_false }
    end

    context "hex str is nil" do
      subject { CommonUtil.check_password(nil, nil)}
      it { should be_false }
    end
  end

  describe "crypt" do
    subject { CommonUtil.crypt("hello") }
    it { should eq Digest::SHA1.hexdigest("hello")}
  end
end

