require 'spec_helper'

describe EntryCandidatesController do
  fixtures :items, :users

  describe "index" do
    context "without login" do
      before do
        xhr :get, :index, :item_name => 'i'
      end

      describe "response" do
        subject { response }
        it { should be_success }
        it_should_behave_like "Unauthenticated Access by xhr"
      end
    end

    context "with login" do
      before do
        login
      end

      context "with no params" do
        before do
          xhr :get, :index
        end

        describe "response" do
          subject { response }
          it { should be_success }
          it { should_not render_template "_candidate"}
        end
      end

      context "with item_name in params" do
        before do
          xhr :get, :index, :item_name => 't'
        end
        describe "response" do
          subject { response }
          it { should be_success }
          it { should render_template "_candidate"}
        end
      end
    end
  end
end
