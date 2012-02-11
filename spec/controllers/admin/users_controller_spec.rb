require 'spec_helper'

describe Admin::UsersController do
  
  def mock_user
    mock_model(User).as_null_object
  end
  describe "index" do
    let(:user_objects) { [mock_user, mock_user, mock_user] }

    describe "Methods calls" do
      specify do
        User.should_receive(:all).and_return(user_objects)
        get :index
        assigns(:users).should == user_objects
      end
    end

    describe "@users" do
      before do
        User.stub(:all).and_return(user_objects)
        get :index
      end

      subject { assigns(:users) }
      it { should == user_objects }
    end
    
    describe "response" do
      before do
        get :index
      end

      subject {response}
      it {should be_success}
      it {should render_template "index"}
    end

  end
  
end
