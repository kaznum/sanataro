require 'spec_helper'

describe EntryCandidatesController, :type => :controller do
  fixtures :items, :users

  describe "index" do
    context "without login" do
      before do
        xhr :get, :index, item_name: 'i'
      end

      describe "response" do
        subject { response }
        it { is_expected.to be_success }
        it_should_behave_like "Unauthenticated Access by xhr"
      end
    end

    context "with login" do
      before do
        dummy_login
      end

      context "with no params" do
        before do
          xhr :get, :index
        end

        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.not_to render_template "_candidate" }
        end
      end

      context "with item_name in params" do
        before do
          xhr :get, :index, item_name: 't'
        end
        describe "response" do
          subject { response }
          it { is_expected.to be_success }
          it { is_expected.to render_template "_candidate" }
        end
      end
    end
  end
end
