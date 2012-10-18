# -*- coding: utf-8 -*-
require 'spec_helper'

describe Api::AccountsController do
  fixtures :users, :accounts

  describe "#index" do
    context "before login," do
      before do
        get :index, :format => :json
      end

      it_should_behave_like "Unauthenticated Access in API"
    end

    context "access successfully with basic auth," do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("user1","123456")
        get :index, format: :json
      end

      describe "response" do
        subject { response }
        it { should be_success }
        it { should render_template :index }
      end
    end

    context "with wrong password at basic auth," do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("user1","1234")
        get :index, format: :json
      end

      it_should_behave_like "Unauthenticated Access in API"
    end

    context "with wrong login at basic auth," do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("user999","123456")
        get :index, format: :json
      end

      it_should_behave_like "Unauthenticated Access in API"
    end

    context "after login," do
      before do
        login
        get :index, format: :json
      end

      describe "response" do
        subject { response }
        it { should be_success }
        it { should render_template :index }
      end
    end
  end
end
