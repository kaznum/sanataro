# -*- coding: utf-8 -*-
require 'spec_helper'

describe ApplicationController do
  describe "change_month" do
    context "with no-xhr get," do
      context "with valid year, month, action," do
        before do
          get :change_month, year: 2008, month: 2, current_action: 'foo'
        end

        describe "response" do
          subject {response}
          it { should redirect_to @controller.url_for(action: 'foo', year: 2008, month: 2) }
        end
      end

      context "with invalid year, month," do
        before do
          get :change_month, year: 2008, month: 22, current_action: 'foo'
        end

        describe "response" do
          subject {response}
          it { should redirect_to current_entries_url }
        end
      end
    end

    context "with xhr get," do
      context "with valid year, month, action," do
        before do
          xhr :get, :change_month, year: 2008, month: 2, current_action: 'foo'
        end

        describe "response" do
          subject {response}
          it { should be_success }
          its(:content_type) { should == 'text/javascript' }
          it { should redirect_by_js_to @controller.url_for(action: 'foo', year: 2008, month: 2) }
        end
      end

      context "with invalid year, month," do
        before do
          xhr :get, :change_month, year: 2008, month: 22, current_action: 'foo'
        end

        describe "response" do
          subject {response }
          it { should be_success }
          its(:content_type) { should == 'text/javascript' }
          it { should redirect_by_js_to current_entries_url }
        end
      end
    end
  end
end
