# -*- coding: utf-8 -*-
require 'spec_helper'

describe EntriesHelper do
  fixtures :users, :accounts
  before do
    @item = Fabricate.build(:item, amount: 1500, from_account_id: 1, to_account_id: 3,)
    @item.save!
    @item.reload
  end

  context "when neither tag nor mark is specified," do
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
end
