# -*- coding: utf-8 -*-
require 'spec_helper'

describe Api::AccountsController do
  fixtures :users, :accounts

  describe "#index" do
    context "before login," do
      before do
        get :index, :format => :json
      end

      it_should_behave_like "Unauthenticated Access"
    end

    context "after login," do
      before do
        login
        get :index, format: :json
      end

      describe "response" do
        subject { response }
        it { should be_success }
      end

      describe "response body" do
        subject { ActiveSupport::JSON.decode(response.body) }
        its(["bankings"]) { should have_at_least(1).accounts }
        its(["incomes"]) { should have_at_least(1).accounts }
        its(["expenses"]) { should have_at_least(1).accounts }
      end
    end
  end
end
