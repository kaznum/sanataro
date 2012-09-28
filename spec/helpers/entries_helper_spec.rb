# -*- coding: utf-8 -*-
require 'spec_helper'

describe EntriesHelper do
  describe "#link_to_confirmation_required" do
    fixtures :users, :accounts, :credit_relations
    before do
      @item = Fabricate.build(:item, amount: 1500, from_account_id: 1, to_account_id: 3,)
      @item.save!
      @item.reload
    end

    context "when neither tag nor mark nor keyword is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true) }
        it { should ==  link_to(I18n.t('label.confirmation_mark'), entry_confirmation_required_path(@item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false) }
        it { should ==  link_to(I18n.t('label.no_confirmation_mark'), entry_confirmation_required_path(@item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when tag is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, tag: "tagtag" ) }
        it { should ==  link_to(I18n.t('label.confirmation_mark'), tag_entry_confirmation_required_path("tagtag", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, tag: "tagtag" ) }
        it { should ==  link_to(I18n.t('label.no_confirmation_mark'), tag_entry_confirmation_required_path("tagtag", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when mark is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, mark: "markmark" ) }
        it { should ==  link_to(I18n.t('label.confirmation_mark'), mark_entry_confirmation_required_path("markmark", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, mark: "markmark" ) }
        it { should ==  link_to(I18n.t('label.no_confirmation_mark'), mark_entry_confirmation_required_path("markmark", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when keyword is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, keyword: "keykey" ) }
        it { should ==  link_to(I18n.t('label.confirmation_mark'), keyword_entry_confirmation_required_path("keykey", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, keyword: "keykey" ) }
        it { should ==  link_to(I18n.t('label.no_confirmation_mark'), keyword_entry_confirmation_required_path("keykey", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end
  end

  describe "#relative_path" do
    fixtures :users, :accounts
    before do
      @user = users(:user1)
      @credit_item = Fabricate.build(:item, amount: 1500, from_account_id: 4, to_account_id: 3)
      @credit_item.save!
      @credit_item.reload
      @credit_date = @credit_item.action_date

      @payment_item = @credit_item.child_item
      @payment_date = @payment_item.action_date

      @single_item = Fabricate.build(:item, amount: 2500)
      @single_item.save!
      @single_item.reload
    end

    context "when the owner of params' id is parent item," do
      subject { helper.relative_path(@credit_item.id) }

      it { should == "/months/#{@payment_date.year}/#{@payment_date.month}/entries#item_#{@payment_item.id}" }
    end

    context "when the owner of params' id is child item," do
      subject { helper.relative_path(@payment_item.id) }

      it { should == "/months/#{@credit_item.year}/#{@credit_item.month}/entries#item_#{@credit_item.id}" }
    end

    context "when the owner of params' id has no relatives," do
      subject { helper.relative_path(@single_item.id) }

      it { should be_nil }
    end

    context "when the params' id does not exist," do
      it { expect { helper.relative_path(31423413) }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end
end







