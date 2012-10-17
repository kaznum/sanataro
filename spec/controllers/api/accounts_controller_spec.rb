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
        it { should render_template :index }
      end
    end
  end
end
