require 'spec_helper'

describe EmojisController do
  fixtures :users

  describe "#index" do
    context "before login," do
      before do
        xhr :get, :index, form_id: "aaabbb"
      end

      it_should_behave_like "Unauthenticated Access by xhr"
    end

    context "after login, " do
      context "when form_id param is missing," do
        before do
          login
          xhr :get, :index
        end

        describe "response" do
          it { should redirect_by_js_to current_entries_url }
        end
      end

      context "when form_id param exists," do
        before do
          login
          xhr :get, :index, form_id: "aaabbb"
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "index" }
        end
      end
    end
  end
end
