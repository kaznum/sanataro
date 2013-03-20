# -*- coding: utf-8 -*-
require 'spec_helper'

describe EntriesHelper do
  describe "#link_to_confirmation_required" do
    fixtures :users, :accounts, :credit_relations
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: 1, to_account_id: 3)
      @item.save!
      @item.reload
    end

    context "when neither tag nor mark nor keyword is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true) }
        it { should ==  link_to('<i class="icon-star item_confirmation_required"></i>'.html_safe, entry_confirmation_required_path(@item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false) }
        it { should ==  link_to('<i class="icon-star-empty item_confirmation_not_required"></i>'.html_safe, entry_confirmation_required_path(@item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when tag is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, tag: "tagtag" ) }
        it { should ==  link_to('<i class="icon-star item_confirmation_required"></i>'.html_safe, tag_entry_confirmation_required_path("tagtag", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, tag: "tagtag" ) }
        it { should ==  link_to('<i class="icon-star-empty item_confirmation_not_required"></i>'.html_safe, tag_entry_confirmation_required_path("tagtag", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when mark is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, mark: "markmark" ) }
        it { should ==  link_to('<i class="icon-star item_confirmation_required"></i>'.html_safe, mark_entry_confirmation_required_path("markmark", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, mark: "markmark" ) }
        it { should ==  link_to('<i class="icon-star-empty item_confirmation_not_required"></i>'.html_safe, mark_entry_confirmation_required_path("markmark", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end

    context "when keyword is specified," do
      context "when now confirmation_required is true," do
        subject { helper.link_to_confirmation_required(@item.id, true, keyword: "keykey" ) }
        it { should ==  link_to('<i class="icon-star item_confirmation_required"></i>'.html_safe, keyword_entry_confirmation_required_path("keykey", @item.id, confirmation_required: false), remote: true, method: :put, class: 'item_confirmation_required') }
      end

      context "when now confirmation_required is false," do
        subject { helper.link_to_confirmation_required(@item.id, false, keyword: "keykey" ) }
        it { should ==  link_to('<i class="icon-star-empty item_confirmation_not_required"></i>'.html_safe, keyword_entry_confirmation_required_path("keykey", @item.id, confirmation_required: true), remote: true, method: :put, class: 'item_confirmation_not_required') }
      end
    end
  end

  describe "#relative_path" do
    fixtures :users, :accounts, :credit_relations

    before do
      @user = users(:user1)
      @credit_item = Fabricate.build(:general_item, amount: 1500, from_account_id: 4, to_account_id: 3)
      @credit_item.save!
      @credit_item.reload
      @credit_date = @credit_item.action_date

      @payment_item = @credit_item.child_item
      @payment_date = @payment_item.action_date

      @single_item = Fabricate.build(:general_item, amount: 2500)
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

  describe "operation icons" do
    before do
      @item = Fabricate.build(:general_item, amount: 1500, from_account_id: 1, to_account_id: 3, action_date: Date.new(2008,5,3))
      @item.save!
      @item.reload
    end

    describe "#link_to_edit" do
      describe "link" do
        subject { helper.link_to_edit(@item) }
        it { should match /href="\/months\/2008\/5\/entries\/#{@item.id}\/edit"/ }
        it { should match /class=".*edit_icon.*"/ }
      end

      context "when disabled," do
        subject { helper.link_to_edit(@item, false) }
        it { should_not match /href="\/months\/2008\/5\/entries\/#{@item.id}\/edit"/ }
        it { should match /class=".*edit_icon.*"/ }
        it { should match /class=".*disabled.*"/ }
      end
    end

    describe "#link_to_destroy" do
      describe "link" do
        subject { helper.link_to_destroy(@item) }
        it { should match /href="\/months\/2008\/5\/entries\/#{@item.id}"/ }
        it { should match /data-method="delete"/ }
        it { should match /class=".*destroy_icon.*"/ }
      end

      context "when disabled," do
        subject { helper.link_to_destroy(@item, false) }
        it { should_not match /href="\/months\/2008\/5\/entries\/#{@item.id}"/ }
        it { should_not match /data-method="delete"/ }
        it { should match /class=".*destroy_icon.*"/ }
        it { should match /class=".*disabled.*"/ }
      end
    end

    describe "#link_to_show" do
      describe "link" do
        subject { helper.link_to_show(@item) }
        it { should match /href="\/months\/2008\/5\/entries#item_#{@item.id}"/ }
        it { should match /class=".*show_icon.*"/ }
      end

      context "when disabled," do
        subject { helper.link_to_show(@item, false) }
        it { should_not match /href="\/months\/2008\/5\/entries#item_#{@item.id}"/ }
        it { should match /class=".*show_icon.*"/ }
        it { should match /class=".*disabled.*"/ }
      end
    end
  end

  describe "#tags_for_items" do
    fixtures :users, :accounts
    context "when tags exist, " do
      before do
        @item = Fabricate.build(:general_item, tag_list: 'aa bb' )
        @item.save!
        @item.reload
        helper.should_receive(:link_to_tag).with(@item.tags[0]).and_return("_link_#{@item.tags[0].name}_")
        helper.should_receive(:link_to_tag).with(@item.tags[1]).and_return("_link_#{@item.tags[1].name}_")
      end

      subject { helper.link_to_tags(@item) }
      it { should == "[_link_aa_ _link_bb_]" }
    end

    context "when tags do not exist, " do
      before do
        @item = Fabricate.build(:general_item)
        @item.save!
        @item.reload
      end

      subject { helper.link_to_tags(@item) }
      it { should == "" }
    end
  end

  describe "#item_row_class" do
    fixtures :users, :accounts
    context "when item is adjustment," do
      before do
        @item = Fabricate.build(:adjustment)
        @item.save!
      end

      subject { helper.item_row_class(@item) }
      it { should == "item_adjustment" }
    end

    context "when item has parent," do
      before do
        item_parent = Fabricate.build(:general_item)
        item_parent.save!
        @item = Fabricate.build(:general_item, parent_id: item_parent.id)
        @item.save
      end

      subject { helper.item_row_class(@item) }
      it { should == "item_move" }
    end

    context "when item is income," do
      before do
        @user = users(:user1)
        @item = Fabricate.build(:general_item, from_account_id: accounts(:income2).id)
        @item.save!
      end

      subject { helper.item_row_class(@item) }
      it { should == "item_income" }
    end
    context "when item is moving," do
      before do
        @user = users(:user1)
        @item = Fabricate.build(:general_item, from_account_id: accounts(:bank1).id, to_account_id: accounts(:bank11).id)
        @item.save!
      end

      subject { helper.item_row_class(@item) }
      it { should == "item_move" }
    end
  end

  describe "#item_row_name" do
    fixtures :users, :accounts
    context "when item is adjustment," do
      before do
        @item = Fabricate.build(:adjustment, adjustment_amount: 5000)
        @item.save!
      end

      subject { helper.item_row_name(@item) }
      it { should == "#{t("label.adjustment")} 5,000円" }
      it { should be_html_safe }
    end

    context "when item has parent," do
      before do
        @user = users(:user1)
        item_parent = Fabricate.build(:general_item, action_date: Date.new(2012,3,10), name: "hello(笑)")
        item_parent.save!
        @item = Fabricate.build(:general_item, parent_id: item_parent.id, action_date: Date.new(2012,5,10), name: "hoge(笑)hoge")
        @item.save
      end

      subject { helper.item_row_name(@item) }
      it { should match /#{t("entries.item.deposit")} \(<a[^>]+>03\/10 hello<span class='emo'>\(笑\)<\/span><\/a>\)/ }
      it { should be_html_safe }
    end

    context "when item has child," do
      before do
        @user = users(:user1)
        @item = Fabricate.build(:general_item, action_date: Date.new(2012,3,10), name: "hello:sushi:")
        @item.save!
        item_child = Fabricate.build(:general_item, parent_id: @item.id, action_date: Date.new(2012,5,10), name: "hogehoge")
        item_child.save
      end

      subject { helper.item_row_name(@item) }
      it { should match /hello<img [^>]+> \(<a[^>]+>05\/10 #{t("entries.item.deposit")}<\/a>\)/ }
      it { should be_html_safe }
    end

    context "when item is a regular one, " do
      before do
        @user = users(:user1)
        @item = Fabricate.build(:general_item, action_date: Date.new(2012,3,10), name: "hello:sushi:")
        @item.save!
      end

      subject { helper.item_row_name(@item) }
      it { should match /^hello<img .+>$/ }
      it { should be_html_safe }
    end
  end

  describe "#item_row_confirmation_required" do
    fixtures :users, :accounts
    context "when item is adjustment, " do
      before do
        @item = Fabricate.build(:adjustment, adjustment_amount: 5000)
        @item.save!
      end

      subject { helper.item_row_confirmation_required(@item, nil, nil, nil) }
      it { should == "" }
    end

    context "when item has parent, " do
      before do
        item_parent = Fabricate.build(:general_item, action_date: Date.new(2012,3,10), confirmation_required: true, name: "hello")
        item_parent.save!
        @item = Fabricate.build(:general_item, parent_id: item_parent.id, action_date: Date.new(2012,5,10), name: "hogehoge")
        @item.save
        helper.should_receive(:link_to_confirmation_required).with(@item.id, true, tag: "TAG", mark: "MARK", keyword: "KEY").and_return("__LINK__")
      end

      subject { helper.item_row_confirmation_required(@item, "TAG", "MARK", "KEY" ) }
      it { should == "__LINK__" }
    end

    context "when item is NOT adjustment, " do
      before do
        @item = Fabricate.build(:general_item, confirmation_required: true)
        @item.save!
        helper.should_receive(:link_to_confirmation_required).with(@item.id, true, tag: "TAG", mark: "MARK", keyword: "KEY").and_return("__LINK__")
      end

      subject { helper.item_row_confirmation_required(@item, "TAG", "MARK", "KEY" ) }
      it { should == "__LINK__" }
    end
  end

  describe "#item_row_from_account" do
    fixtures :users, :accounts
    context "when item is adjustment, " do
      context "amount is less than 0," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: -200000, adjustment_amount: -40000)
          helper.should_receive(:colored_account_name).with(@item.to_account_id).and_return("ACCOUNT_NAME")
        end

        subject { helper.item_row_from_account(@item)  }
        it { should == "ACCOUNT_NAME" }
      end

      context "amount is more than 0," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: 200000)
          helper.should_not_receive(:colored_account_name).with(@item.to_account_id)
        end

        subject { helper.item_row_from_account(@item)  }
        it { should == "(#{t("label.adjustment")})" }
      end
    end
    context "when item is NOT adjustment, " do
      before do
        @item = Fabricate.build(:general_item)
        @item.save!
        helper.should_receive(:colored_account_name).with(@item.from_account_id).and_return("ACCOUNT_NAME")
      end

      subject { helper.item_row_from_account(@item)  }
      it { should == "ACCOUNT_NAME" }
    end
  end

  describe "#item_row_to_account" do
    fixtures :users, :accounts
    context "when item is adjustment, " do
      context "amount is more than 0," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: 200000)
          helper.should_receive(:colored_account_name).with(@item.to_account_id).and_return("ACCOUNT_NAME")
        end

        subject { helper.item_row_to_account(@item)  }
        it { should == "ACCOUNT_NAME" }
      end

      context "amount is less than 0," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: -200000, adjustment_amount: -400000)
          helper.should_not_receive(:colored_account_name).with(@item.to_account_id)
        end

        subject { helper.item_row_to_account(@item)  }
        it { should == "(#{t("label.adjustment")})" }
      end
    end

    context "when item is NOT adjustment, " do
      before do
        @item = Fabricate.build(:general_item)
        @item.save!
        helper.should_receive(:colored_account_name).with(@item.to_account_id).and_return("ACCOUNT_NAME")
      end

      subject { helper.item_row_to_account(@item)  }
      it { should == "ACCOUNT_NAME" }
    end
  end

  describe "#item_row_operation" do
    fixtures :users, :accounts
    context "when item is adjustment," do
      context "when only_show is true," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: 200000)
          helper.should_receive(:link_to_show).with(@item).and_return("SHOW_LINK")
        end

        subject { helper.item_row_operation(@item, true)}
        it { should == "SHOW_LINK" }
      end
      context "when only_show is false," do
        before do
          @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: 200000)
          helper.should_not_receive(:link_to_show).with(@item)
          helper.should_receive(:item_row_twitter_button).with(@item).and_return("_TWEET_")
          helper.should_receive(:link_to_edit).with(@item).and_return("_EDIT_")
          helper.should_receive(:link_to_destroy).with(@item, true).and_return("_DESTROY_")
        end

        subject { helper.item_row_operation(@item)}
        it { should == "_TWEET__EDIT__DESTROY_" }
      end
    end
  end

  describe "#item_row_twitter_button" do
    fixtures :users, :accounts
    context "when item is adjustment," do
      before do
        @item = Fabricate.build(:adjustment, from_account_id: -1, to_account_id: accounts(:bank1).id, amount: 200000)
      end

      subject { helper.item_row_twitter_button(@item) }
      it { should == "" }
    end

    context "when item has parent," do
      before do
        @item = Fabricate.build(:general_item, parent_id: 20)
      end

      subject { helper.item_row_twitter_button(@item) }
      it { should == "" }
    end

    context "when item is regular," do
      before do
        @item = Fabricate.build(:general_item)
        helper.should_receive(:tweet_button).with(@item).and_return("__TWEET__")
      end

      subject { helper.item_row_twitter_button(@item) }
      it { should == "__TWEET__" }
    end
  end
end
