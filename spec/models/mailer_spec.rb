# -*- coding: utf-8 -*-
require 'spec_helper'

describe Mailer do
  describe "signup_confirmation" do
    let(:user) { mock_model(User, email: "foo@example.com", login: "userhogehoge", confirmation: "AABBCCDD") }
    let(:mail) { Mailer.signup_confirmation(user) }

    describe "mail" do
      subject{mail}
      its(:subject) { should == "[#{Settings.product_name}] ユーザ登録は完了していません" }
      its(:to) {should == [user.email]}
      its(:from) { should == [Settings.system_mail_address] }
    end

    describe "user" do
      subject { mail.body.encoded }
      it { should match(user.login) }
    end
  end

  describe "signup_complete" do
    let(:user) { mock_model(User, email: "foo@example.com", login: "userhogehoge", confirmation: "AABBCCDD") }
    let(:mail) { Mailer.signup_complete(user) }

    describe "mail" do
      subject{mail}
      its(:subject) { should == "[#{Settings.product_name}] ユーザ登録完了" }
      its(:to) {should == [user.email]}
      its(:from) { should == [Settings.system_mail_address] }
    end

    describe "user" do
      subject { mail.body.encoded }
      it { should match(user.login) }
    end
  end
end
