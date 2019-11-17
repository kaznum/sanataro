# -*- coding: utf-8 -*-
require 'spec_helper'

describe TagStatusesController, :type => :controller do
  fixtures :users, :items, :accounts

  describe 'show' do
    context 'before login' do
      before do
        xhr :get, :show
      end
      it_should_behave_like 'Unauthenticated Access by xhr'
    end

    context 'after login' do
      before do
        dummy_login
        # test data
        create_entry entry: { action_date: '2008/2/3', name: 'テスト1' , amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'abc def' }, year: 2008, month: 2
        create_entry entry: { action_date: '2008/2/3',  name: 'テスト2' , amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'abc ' }, year: 2008, month: 2
        create_entry entry: { action_date: '2008/2/3',  name: 'テスト3' , amount: '10,000', from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'def' }, year: 2008, month: 2
        xhr :get, :show
      end

      describe 'response' do
        subject { response }
        it { is_expected.to be_success }
        it { is_expected.to render_template 'show' }
      end

      describe '@tags' do
        subject { assigns(:tags) }
        it { is_expected.not_to be_nil }
        it 'has at least 1 tag' do
          expect(subject.size).to be >= 1
        end
      end

      describe 'uniqueness' do
        subject { assigns(:tags) }

        describe '#size' do
          subject { super().size }
          it { is_expected.to eq(assigns(:tags).map(&:name).uniq.size) }
        end
      end
    end
  end
end
