require 'spec_helper'

describe User do
	fixtures :users, :items, :accounts, :credit_relations


  describe "create" do
    before do
      valid_attrs = {
        :login => 'test_1',
        :password_plain => '123-4_56',
        :password_confirmation => '123-4_56',
        :email => 'test@hoge.example.com'
      }
      @user = User.new(valid_attrs)
    end

    context "when all attributes are valid" do 
      subject {
        @user.save
        @user
      }

      it { should_not be_new_record }
      its(:password) { should == Digest::SHA1.hexdigest('test_1'+'123-4_56') }
      its(:created_at) { should_not be_nil }
      its(:updated_at) { should_not be_nil }
      its(:is_active?) { should be_true }
    end

    context "when without email" do
      subject {
        @user.email = ''
        @user.save
        @user
      }
      it { should be_new_record }
      specify { subject.errors[:email].should_not be_empty }
    end
  

    describe "when email is formatted wrong" do
      subject {
        @user.email = 'test.example.com'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:email].should_not be_empty }
    end

    describe "when email is too short" do
      subject {
        @user.email = 't@e.c'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:email].should_not be_empty }
    end

    describe "when password_plain and password_confirmation are not same" do
      subject {
        @user.password_confirmation = 'ddddddddd'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:password_plain].should_not be_empty }
    end

    describe "when login is not set" do
      subject {
        @user.login = nil
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:login].should_not be_empty }
    end

    describe "when login is too short" do
      subject {
        @user.login = '11'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:login].should_not be_empty }
    end
    
    describe "when login is too long" do
      subject {
        @user.login = '12345678901'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:login].should_not be_empty }
    end
    
    describe "when both of passwords are not set" do
      subject {
        @user.password_plain = nil
        @user.password_confirmation = nil
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:password_plain].should_not be_empty }
    end

    describe "when both of passwords are too short" do
      subject {
        @user.password_plain = '12345'
        @user.password_confirmation = '12345'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:password_plain].should_not be_empty }
    end

    describe "when both of passwords are too long" do
      subject {
        @user.password_plain = '12345678901'
        @user.password_confirmation = '12345678901'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:password_plain].should_not be_empty }
    end
    
    describe "when both of passwords have invalid chars" do
      subject {
        @user.password_plain = '1234.56'
        @user.password_confirmation = '1234.56'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:password_plain].should_not be_empty }
    end
    
    describe "when login has invalid chars" do
      subject {
        @user.login = 'te.st1'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:login].should_not be_empty }
    end

    describe "when login is not unique" do
      subject {
        @user.login = 'user1'
        @user.save
        @user
      }

      it { should be_new_record }
      specify { subject.errors[:login].should_not be_empty }
    end
  end
  
  describe "update" do 
    before do
      @old_user = User.find(1)
      @user = User.find(1)
    end
    
    context "when password changed correctly" do
      subject {
        @user.password_plain = '12-3456'
        @user.password_confirmation = '12-3456'
        @user.save
        @user
      }

      specify { subject.errors[:password_plain].should be_empty }
      its(:updated_at) { should > @old_user.updated_at }
    end
    
    context "when without_password" do
      subject {
        @user.password_plain = ''
        @user.password_confirmation = ''
        @user.login
        @user
      }
      
      specify { subject.errors.should be_empty }
      its(:updated_at) { should == @old_user.updated_at }
    end
  end

  describe "associations" do 
    describe "it has accounts" do
      subject { users(:user1).accounts }
      it { should_not be_empty }
    end
    
    describe "it has credit_relations" do
      subject { users(:user1).credit_relations }
      it { should_not be_empty }
    end

    
    describe "it has items" do
      subject { users(:user1).items }

      it { should_not be_empty }
      specify {
        subject.each do |item|
          item.should_not be_nil
        end
      }

      specify {
        subject.where("action_date < ?", Date.new(2008,3)).all.should_not be_empty
      }
      specify {
        subject.where(:user_id => 101).should have(0).records
      }
      specify {
        subject.where(:user_id => 1).size.should > 0
      }
    end
  end

  describe "get_categorized_accounts" do
    before do
      @user1 = users(:user1)
      @h_accounts = @user1.get_categorized_accounts
    end

    subject { @h_accounts }
    specify { subject.size.should > 0 }
    
    specify {
      actual = @user1.accounts.where(:account_type => ['account', 'income']).size
      subject[:from_accounts].should have(actual).records
    }

    specify {
      actual = @user1.accounts.where(:account_type => ['account', 'outgo']).size
      subject[:to_accounts].should have(actual).records
    }

    specify {
      actual = @user1.accounts.where(:account_type => 'account').size
      subject[:bank_accounts].should have(actual).records
    }

    specify {
      actual = @user1.accounts.where(:account_type => ['account','income','outgo']).size
      subject[:all_accounts].should have(actual).records
    }
    
    specify {
      actual = @user1.accounts.where(:account_type => 'income').size
      subject[:income_ids].should have(actual).records
    }

    specify {
      actual = @user1.accounts.where(:account_type => 'outgo').size
      subject[:outgo_ids].should have(actual).records
    }
    
    specify {
      actual = @user1.accounts.where(:account_type => 'account').size
      subject[:account_ids].should have(actual).records
    }
    
    specify {
      actual = @user1.accounts.where("bgcolor IS NOT NULL").size
      subject[:account_bgcolors].should have(actual).records
    }
  end

  describe "#deliver_signup_confirmation" do
    let(:user) { User.new }
    specify {
      mock_obj = double
      mock_obj.should_receive(:deliver)
      Mailer.should_receive(:signup_confirmation).with(user).and_return(mock_obj)
      user.deliver_signup_confirmation
    }
  end
  
  describe "#deliver_signup_complete" do
    let(:user) { User.new }
    specify {
      mock_obj = double
      mock_obj.should_receive(:deliver)
      Mailer.should_receive(:signup_complete).with(user).and_return(mock_obj)
      user.deliver_signup_complete
    }
  end
end
