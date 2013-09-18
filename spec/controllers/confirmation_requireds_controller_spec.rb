require 'spec_helper'

describe ConfirmationRequiredsController do
  fixtures :items, :accounts, :users

  describe "#update" do
    context "without login," do
      before do
        xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true'
      end
      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login" do
      before do
        login
      end

      context "when tag is specified," do
        before do
          items(:item3).update_attributes!(:confirmation_required => false)
          xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true', :tag => "abc"
        end

        describe "item" do
          subject { Item.find(items(:item3).id)}
          it { should be_confirmation_required }
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "update" }
        end

        describe "@tag" do
          subject { assigns(:tag) }
          it { should == 'abc' }
        end

        describe "@mark" do
          subject { assigns(:mark) }
          it { should be_nil }
        end
      end

      context "when keyword is specified," do
        before do
          items(:item3).update_attributes!(:confirmation_required => false)
          xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true', :keyword => "abc"
        end

        describe "item" do
          subject { Item.find(items(:item3).id)}
          it { should be_confirmation_required }
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "update" }
        end

        describe "@keyword" do
          subject { assigns(:keyword) }
          it { should == 'abc' }
        end

        describe "@mark" do
          subject { assigns(:mark) }
          it { should be_nil }
        end

        describe "@tag" do
          subject { assigns(:tag) }
          it { should be_nil }
        end
      end

      context "when mark is specified," do
        before do
          items(:item3).update_attributes!(:confirmation_required => false)
          xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true', :mark => "abc"
        end

        describe "item" do
          subject { Item.find(items(:item3).id)}
          it { should be_confirmation_required }
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "update" }
        end

        describe "@tag" do
          subject { assigns(:tag) }
          it { should be_nil }
        end

        describe "@mark" do
          subject { assigns(:mark) }
          it { should == 'abc' }
        end
      end


      context "when changing status from false to true," do
        before do
          items(:item3).update_attributes!(:confirmation_required => false)
          xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'true'
        end

        describe "item" do
          subject { Item.find(items(:item3).id)}
          it { should be_confirmation_required }
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "update" }
        end
      end

      context "when changing status from true to false," do
        before do
          items(:item3).update_attributes!(:confirmation_required => true)
          xhr :put, :update, :entry_id => items(:item3).id, :confirmation_required => 'false'
        end

        describe "item" do
          subject { Item.find(items(:item3).id)}
          it { should_not be_confirmation_required }
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "update" }
        end
      end

      context "when parent_id exists," do
        before do
          old_credit_refill = items(:credit_refill31)

          xhr :put, :update, :entry_id => old_credit_refill.id, :confirmation_required => 'true'
        end


        describe "credit card account(parent)" do
          subject { Item.find(items(:credit_payment21).id)}
          it { should be_confirmation_required }
        end

        describe "payment account (child)" do
          subject { Item.find(items(:credit_refill31).id)}
          it { should_not be_confirmation_required }
        end
      end

      context "when entry_id is invalid," do
        before do
          xhr :put, :update, :confirmation_required => 'false', :entry_id => 324123413
        end

        subject { response }
        it { should redirect_by_js_to current_entries_url }
      end

      context "when status is not set," do
        before do
          xhr :put, :update, :entry_id => items(:item3).id
        end

        subject { response }
        it { should redirect_by_js_to current_entries_url }
      end
    end
  end
end
