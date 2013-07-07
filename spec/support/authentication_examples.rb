    shared_examples_for "Unauthenticated Access" do
      subject { response }
      it { should redirect_to login_url }
    end

    shared_examples_for "Unauthenticated Access in API" do
      subject { response }
      its(:response_code) { should == 401 }
    end

    shared_examples_for "Unauthenticated Access by xhr" do
      subject { response }
      it { should redirect_by_js_to login_url }
    end

    shared_examples_for "Not Acceptable" do
      subject { response }
      its(:status) { should == 406 }
    end

