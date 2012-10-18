# -*- coding: utf-8 -*-
require 'spec_helper'

describe Api::SessionsController do
  fixtures :users

  describe "#create" do
    context "when params[:session] does not mismatch," do
      before do
        @action = -> { post :create, login: users(:user1).login, password: "123456" }
      end

      describe "response" do
        before { @action.call }
        subject { response }

        its(:response_code) { should == 401 }
      end

      describe "session" do
        before { @action.call }
        subject { session }

        its([:user_id]) { should be_nil }
      end
    end

    context "when user doesn't exist," do
      before do
        @action = -> { post :create, session: { login: "not_exist", password: "not_exist_pass"} }
      end

      describe "response" do
        before { @action.call }
        subject { response }

        its(:response_code) { should == 401 }
      end

      describe "session" do
        before { @action.call }
        subject { session }

        its([:user_id]) { should be_nil }
      end
    end

    context "when user exists but password mismatches," do
      before do
        @action = -> { post :create, session: { login: users(:user1).login, password: "not_match_pass"} }
      end

      describe "response" do
        before { @action.call }
        subject { response }

        its(:response_code) { should == 401 }
      end

      describe "session" do
        before { @action.call }
        subject { session }

        its([:user_id]) { should be_nil }
      end
    end

    context "when user exists and password matches," do
      before do
        @action = -> { post :create, session: { login: users(:user1).login, password: "123456"} }
      end

      describe "response" do
        before { @action.call }
        subject { response }

        its(:response_code) { should == 200 }
      end

      describe "session" do
        before { @action.call }
        subject { session }

        its([:user_id]) { should == users(:user1).id }
      end
    end
  end
end
