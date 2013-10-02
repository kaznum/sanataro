# -*- coding: utf-8 -*-
require 'spec_helper'

describe AutologinKey do
  fixtures :autologin_keys, :users

  context "when create" do
    it "正常に作成できること" do
      ak = AutologinKey.new
      ak.user_id = users(:user1).id
      ak.autologin_key = '12345678'
      ak.save.should be_true
      ak.created_at.should_not be_nil
      ak.updated_at.should_not be_nil
      ak.enc_autologin_key.should_not be_blank
    end

    context "when no user_id" do
      it "保存できないこと" do
        ak = AutologinKey.new
        ak.autologin_key = '12345678'
        ak.save.should be_false
        ak.errors[:user_id].should_not be_empty
      end
    end

    context "when no key" do
      it "保存できないこと" do
        ak = AutologinKey.new
        ak.user_id = users(:user1).id
        ak.save.should be_false
        ak.errors[:autologin_key].should_not be_empty
      end
    end
  end

  context "when update," do
    let!(:old_ak) { autologin_keys(:autologin_key1) }
    context "when params are valid," do
      before do
        new_ak = AutologinKey.find(old_ak.id)
        new_ak.autologin_key = '88345687'
        @action = -> { new_ak.save! }
      end
      specify { expect { @action.call }.not_to raise_error }
      specify { expect { @action.call }.to change { AutologinKey.find(old_ak.id).enc_autologin_key } }
    end

    context "when user_id is nil," do
      let(:invalid_ak) {
        ak = AutologinKey.find(old_ak.id)
        ak.user_id = nil
        ak
      }

      specify { expect(invalid_ak.save).to be_false }
      specify { expect(!invalid_ak.save && invalid_ak).to have_at_least(1).errors_on :user_id }
    end
  end

  context "when evaluation" do
    before do
      ak = AutologinKey.new
      ak.user_id = users(:user1).id
      ak.autologin_key = '12345678'
      ak.save!
    end

    it "正しいキーで取得可能であること" do
      AutologinKey.matched_key(users(:user1).id, '12345678').should_not be_nil
    end

    it "不正なキーで取得できないこと" do
      AutologinKey.matched_key(users(:user1).id, '12367').should be_nil
    end

    context "when the key was created more than 30 days ago" do
      before do
        ak = AutologinKey.new
        ak.user_id = users(:user1).id
        ak.autologin_key = '55555555'
        ak.created_at = Time.now - (31 * 24 * 3600)
        ak.save!
      end

      it "取得できないこと" do
        AutologinKey.matched_key(users(:user1).id, '55555555').should be_nil
      end
    end
  end

  context "when cleanup is called" do
    context "when there is a record which was created more than 30 days ago" do
      before do
        ak = AutologinKey.new
        ak.user_id = users(:user1).id
        ak.autologin_key = '12345678'
        ak.created_at = Time.now - (50 * 24 * 3600)
        ak.save!
        @old_count = AutologinKey.count
        AutologinKey.cleanup
      end

      describe "records" do
        subject { AutologinKey.count }
        it { should < @old_count }
      end

      describe "current records" do
        subject { AutologinKey.where("created_at < ?", Time.now - 30 * 24 * 3600).to_a }
        it { should have(0).records }
      end
    end
  end
end
