# -*- coding: utf-8 -*-
require 'spec_helper'

describe TagStatusesController do
  fixtures :items, :accounts

  describe "show" do
    context "before login" do
      before do
        xhr :get, :show
      end
      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login" do
      before do
        login
        # test data
        create_entry :action_date => '2008/2/3',  :item_name=>'テスト1' , :amount=>'10,000', :from=>accounts(:bank1).id, :to=>accounts(:outgo3).id, :tag_list => 'abc def', :year => 2008, :month => 2
        xhr :get, :show
      end

      describe "response" do
        subject { response }
        it {should be_success }
        it {should render_template "show"}
      end

      describe "@tags" do
        subject { assigns(:tags) }
        it {should_not be_nil}
        it {should have_at_least(1).tags}
      end
    end
  end

  describe "destroy" do
    context "before login" do
      before do
        xhr :delete, :destroy
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login" do
      before do
        login
        xhr :delete, :destroy
      end

      subject {response}
      it { should be_success }
      it { should render_template "destroy" }
    end
  end
end

