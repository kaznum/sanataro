require 'spec_helper'

describe ConfirmationStatusesController do
  fixtures :all

  describe "#show" do 
    context "before login," do
      before do
        xhr :get, :show
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login," do
      before do
        login
        xhr :get, :show
      end
      describe "response" do 
        subject { response }
        it { should render_template "show" }
      end

      describe "@entries" do
        subject { assigns(:entries)}
        it { should_not be_empty }
      end
    end
  end
  
  describe "#destroy" do 
    context "before login," do
      before do
        xhr :delete, :destroy
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login," do
      before do
        login
        xhr :delete, :destroy
      end

      subject { response }
      it { should render_template "destroy" }
    end
  end
end
