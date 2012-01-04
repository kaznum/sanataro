require 'spec_helper'

describe Api::EntriesController do
  fixtures :all
  describe "GET index" do
    context "before login," do
      before do
        get :index, :year_month => "200802", :format => :json
      end
      describe "response" do
        subject {response}
        it {should redirect_to login_url}
      end
    end

    context "after login," do
      before do
        login
      end

      context "without params" do
        before do
          get :index, :format => :json
        end

        describe "response" do
          subject {response}
          it {should redirect_to login_url}
        end
      end
      context "invalid params" do
        context "when params[:year_month] = 12345," do
          before do
            get :index, :year_month => "12345", :format => :json
          end

          describe "response" do
            subject {response}
            it {should redirect_to login_url}
          end
        end
      end

      context "with valid params" do
        before do
          get :index, :year_month => "200802", :format => :json
        end

        describe "response" do
          subject {response}
          it {should be_success}
          its(:content_type) {should == 'application/json' }
          specify {
            expect{ActiveSupport::JSON.decode(subject.body).not_to raise_error}
          }
        end

        describe "@year" do
          subject { assigns(:year)}
          it { should == 2008 }
        end

        describe "@month" do
          subject { assigns(:month)}
          it { should == 2 }
        end

        describe "@user" do
          subject { assigns(:user)}
          it { should be_instance_of User }
          its(:id) { should == users(:user1).id}
        end
      end
    end
  end
end
