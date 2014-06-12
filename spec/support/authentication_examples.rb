    shared_examples_for "Unauthenticated Access" do
      subject { response }
      it { is_expected.to redirect_to login_url }
    end

    shared_examples_for "Unauthenticated Access in API" do
      subject { response }

      describe '#response_code' do
        subject { super().response_code }
        it { is_expected.to eq(401) }
      end
    end

    shared_examples_for "Unauthenticated Access by xhr" do
      subject { response }
      it { is_expected.to redirect_by_js_to login_url }
    end

    shared_examples_for "Not Acceptable" do
      subject { response }

      describe '#status' do
        subject { super().status }
        it { is_expected.to eq(406) }
      end
    end
