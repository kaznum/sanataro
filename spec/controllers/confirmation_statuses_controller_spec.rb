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
        dummy_login
        xhr :get, :show
      end
      describe "response" do
        subject { response }
        it { should render_template "show" }
      end

      describe "@entries" do
        subject { assigns(:entries) }
        it { should_not be_empty }
      end
    end
  end
end
