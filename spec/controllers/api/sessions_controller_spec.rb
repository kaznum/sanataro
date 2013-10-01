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
        @action = -> { post :create, session: { login: "not_exist", password: "not_exist_pass" } }
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
        @action = -> { post :create, session: { login: users(:user1).login, password: "not_match_pass" } }
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
        @action = -> { post :create, session: { login: users(:user1).login, password: "123456" }, format: :json }
      end

      describe "response" do
        before { @action.call }
        subject { response }

        its(:response_code) { should == 200 }
        its(:body) { should match /{"authenticity_token":".+"}/  }
      end

      describe "session" do
        before { @action.call }
        subject { session }

        its([:user_id]) { should == users(:user1).id }
      end
    end
  end

  describe "#destroy" do

    describe "when user has not been logged in," do
      before { delete :destroy }
      describe "response" do
        subject { response }
        its(:response_code) { should == 200 }
      end

      describe "session" do
        subject { session }
        its([:user_id]) { should be_nil }
      end
    end

    describe "when user has been logged in," do
      before do
        session[:user_id] = users(:user1).id
        delete :destroy
      end

      describe "response" do
        subject { response }
        its(:response_code) { should == 200 }
      end

      describe "session" do
        subject { session }
        its([:user_id]) { should be_nil }
      end
    end
  end
end
