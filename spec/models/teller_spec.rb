# frozen_string_literal: true

require 'spec_helper'

describe Teller, type: :model do
  fixtures :all
  describe '#create_entry' do
    context 'when validation errors happen,' do
      before do
        @initial_count = Item.count
        @action = -> { Teller.create_entry(users(:user1), action_date: Date.today, name: '', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga') }
      end

      describe 'raise error' do
        it { expect { @action.call }.to raise_error(ActiveRecord::RecordInvalid) }
      end

      describe 'Item.count' do
        let(:item_count) do
          @action.call
          raise 'DO NOT PASS THROUGH HERE'
        rescue ActiveRecord::RecordInvalid
          return Item.count
        end

        subject { item_count }
        it { is_expected.to eq(@initial_count) }
      end
    end

    shared_examples_for "created successfully with tag_list == 'hoge fuga'" do
      let(:tag_ids) { Tag.where(name: 'hoge').pluck(:id) }

      describe 'tags count' do
        subject { Tag.where(name: 'hoge').to_a }
        it 'has 1 tag' do
          expect(subject.size).to eq(1)
        end
      end

      describe "taggings' size" do
        subject { Tagging.where(tag_id: tag_ids).size }
        it { is_expected.to eq(1) }
      end

      describe "taggings' user_id" do
        subject { Tagging.where(tag_id: tag_ids).pluck(:user_id).all? { |i| users(:user1).id == i } }
        it { is_expected.to be_truthy }
      end

      describe "taggings' taggable_type" do
        subject { Tagging.where(tag_id: tag_ids).pluck(:taggable_type).all? { |t| t == 'Item' } }
        it { is_expected.to be_truthy }
      end
    end

    context 'with confimation_required == true,' do
      before do
        @prev_count = Item.count
        @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: Date.today, name: 'テスト', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga', confirmation_required: true)
      end

      describe 'created_item' do
        subject { @item }

        describe '#errors' do
          subject { super().errors }
          it { is_expected.to be_empty }
        end
      end

      describe 'is_error' do
        subject { @is_error }
        it { is_expected.to be_falsey }
      end

      describe 'Item.count' do
        subject { Item.count }
        it { is_expected.to eq(@prev_count + 1) }
      end

      describe 'created item' do
        subject do
          id = Item.maximum('id')
          Item.find_by_id(id)
        end

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('テスト') }
        end

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(10_000) }
        end

        describe '#tag_list' do
          subject { super().tag_list }
          it { is_expected.to eq('fuga hoge') }
        end
      end

      it_should_behave_like "created successfully with tag_list == 'hoge fuga'"
    end

    context 'with confimation_required is nil,' do
      before do
        @prev_count = Item.count
        @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: Date.today, name: 'テスト', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id, tag_list: 'hoge fuga')
      end

      describe 'created_item' do
        subject { @item }

        describe '#errors' do
          subject { super().errors }
          it { is_expected.to be_empty }
        end
      end

      describe 'is_error' do
        subject { @is_error }
        it { is_expected.to be_falsey }
      end

      describe 'Item.count' do
        subject { Item.count }
        it { is_expected.to eq(@prev_count + 1) }
      end

      describe 'created item' do
        subject do
          id = Item.maximum('id')
          Item.find_by_id(id)
        end

        describe '#name' do
          subject { super().name }
          it { is_expected.to eq('テスト') }
        end

        describe '#amount' do
          subject { super().amount }
          it { is_expected.to eq(10_000) }
        end
        it { is_expected.not_to be_confirmation_required }

        describe '#tag_list' do
          subject { super().tag_list }
          it { is_expected.to eq('fuga hoge') }
        end
      end

      it_should_behave_like "created successfully with tag_list == 'hoge fuga'"
    end

    context 'about relation of created item, adjustment, pl,' do
      before do
        @prev_count = Item.count
        @init_adj2 = Item.find(items(:adjustment2).id)
        @init_adj4 = Item.find(items(:adjustment4).id)
        @init_adj6 = Item.find(items(:adjustment6).id)
        @init_pl0712 = monthly_profit_losses(:bank1200712)
        @init_pl0801 = monthly_profit_losses(:bank1200801)
        @init_pl0802 = monthly_profit_losses(:bank1200802)
        @init_pl0803 = monthly_profit_losses(:bank1200803)
      end

      shared_examples_for 'created only itself successfully' do
        describe 'returned created_item' do
          before do
            @create.call
          end

          subject { @item }

          describe '#errors' do
            subject { super().errors }
            it { is_expected.to be_empty }
          end
        end

        describe 'is_error' do
          before do
            @create.call
          end

          subject { @is_error }
          it { is_expected.to be_falsey }
        end

        describe 'created item' do
          before do
            @create.call
          end
          subject do
            id = Item.maximum('id')
            Item.find_by_id(id)
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq('テスト10') }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end
        end

        describe 'Item.count' do
          it { expect { @create.call }.to change { Item.count }.by(1) }
        end
      end

      context 'created before adjustment which is in the same month,' do
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: @init_adj2.action_date - 1, name: 'テスト10', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id) }
        end

        it_should_behave_like 'created only itself successfully'

        describe 'adjustment just next to the created item' do
          it { expect { @create.call }.to change { Item.find(items(:adjustment2).id).amount }.by(10_000) }
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end

          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(items(:adjustment2).id) }
          end
        end

        describe 'adjustment which is the next of the adjustment next to the created item' do
          it { expect { @create.call }.not_to change { Item.find(items(:adjustment4).id).amount } }
        end

        describe 'adjustment which is the second next of the adjustment next to the created item' do
          it { expect { @create.call }.not_to change { Item.find(items(:adjustment6).id).amount } }
        end

        describe 'monthly pl which is before the created item' do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id) } }
        end

        describe 'monthly pl of the same month of the created item' do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id) } }
        end

        describe 'monthly pl of the next month of the created item' do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id) } }
        end
      end

      context 'created between adjustments which both are in the same month of the item to create,' do
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: @init_adj4.action_date - 1, name: 'テスト10', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id) }
        end

        it_should_behave_like 'created only itself successfully'

        describe 'adjustment which is before the created item' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj2.id).amount } }
        end

        describe 'adjustment which is next to the created item in the same month' do
          it { expect { @create.call }.to change { Item.find(@init_adj4.id).amount }.by(10_000) }
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end

          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(items(:adjustment4).id) }
          end
        end

        describe 'adjustment which is second next to the created item in the next month' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj6.id).amount } }
        end

        describe "the adjusted account's monthly_pl of the last month of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
        end

        describe "the adjusted account's monthly_pl of the same month as that of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
        end

        describe "the adjusted account's monthly_pl of the next month of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
        end

        describe "the non-adjusted account's monthly_pl of the next month of the created item" do
          before do
            @create.call
          end
          subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
          it { is_expected.to be_nil }
        end

        describe "the non-adjusted account's monthly_pl of the same month as the created item" do
          it { expect { @create.call }.to change { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
        end
      end

      context 'created between adjustments, and the one is on earlier date in the same month and the other is in the next month of the item to create,' do
        # adj4とadj6の間(adj4と同じ月)
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: @init_adj4.action_date + 1, name: 'テスト10', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id) }
        end

        it_should_behave_like 'created only itself successfully'

        describe 'the adjustment of the month before the item' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj2.id).amount } }
        end

        describe 'the adjustments of the date before the item' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj2.id).amount } }
          it { expect { @create.call }.not_to change { Item.find(@init_adj4.id).amount } }
        end

        describe 'the adjustments of the next of item' do
          it { expect { @create.call }.to change { Item.find(@init_adj6.id).amount }.by(10_000) }
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end

          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(items(:adjustment6).id) }
          end
        end

        describe "the adjusted account's monthly_pl of the last month of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }
        end

        describe "the adjusted account's monthly_pl of the same month as that of the created item" do
          it { expect { @create.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount }.by(-10_000) }
        end

        describe "the adjusted account's monthly_pl of the next month of the created item" do
          it { expect { @create.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(10_000) }
        end

        describe "the non-adjusted account's monthly_pl of the next month of the created item" do
          before do
            @create.call
          end
          subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first }
          it { is_expected.to be_nil }
        end

        describe "the non-adjusted account's monthly_pl of the same month as the created item" do
          it { expect { @create.call }.to change { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 2, 1)).first.amount }.by(10_000) }
        end
      end

      context "created between adjustments, and the one which is after item's date is in the same month and the other is in the previous month of the item to create," do
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: @init_adj6.action_date - 1, name: 'テスト10', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id) }
        end

        it_should_behave_like 'created only itself successfully'

        describe 'the adjustment of the month before the item' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj2.id).amount } }
          it { expect { @create.call }.not_to change { Item.find(@init_adj4.id).amount } }
        end

        describe 'the adjustments of the next of item' do
          it { expect { @create.call }.to change { Item.find(@init_adj6.id).amount }.by(10_000) }
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end

          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(items(:adjustment6).id) }
          end
        end

        describe "the adjusted account's monthly_pl of the last month or before of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }

          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
        end

        describe "the adjusted account's monthly_pl of the same month as that of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount } }
        end

        describe "the non-adjusted account's monthly_pl of the same month as the created item which does not exist before." do
          before do
            @create.call
          end
          subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first.amount }
          it { is_expected.to eq(10_000) }
        end
      end

      context "created after any adjustments, and the one is item's date is in the same month and the others are in the previous month of the item to create," do
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: @init_adj6.action_date + 1, name: 'テスト10', amount: 10_000, from_account_id: accounts(:bank1).id, to_account_id: accounts(:expense3).id) }
        end

        it_should_behave_like 'created only itself successfully'

        describe 'the adjustment of the month before the item' do
          it { expect { @create.call }.not_to change { Item.find(@init_adj2.id).amount } }
          it { expect { @create.call }.not_to change { Item.find(@init_adj4.id).amount } }
          it { expect { @create.call }.not_to change { Item.find(@init_adj6.id).amount } }
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end
          subject { @affected_item_ids }
          it { is_expected.to be_empty }
        end

        describe "the adjusted account's monthly_pl of the last month or before of the created item" do
          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200801).id).amount } }

          it { expect { @create.call }.not_to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200802).id).amount } }
        end

        describe "the adjusted account's monthly_pl of the same month as that of the created item" do
          it { expect { @create.call }.to change { MonthlyProfitLoss.find(monthly_profit_losses(:bank1200803).id).amount }.by(-10_000) }
        end

        describe "the non-adjusted account's monthly_pl of the same month as the created item which does not exist before." do
          before do
            @create.call
          end
          subject { MonthlyProfitLoss.where(account_id: accounts(:expense3).id, month: Date.new(2008, 3, 1)).first.amount }
          it { is_expected.to eq(10_000) }
        end
      end
    end

    context 'about credit card payment,' do
      shared_examples_for 'created itself and credit payment item successfully' do
        describe 'returned created_item' do
          before do
            @create.call
          end

          subject { @item }

          describe '#errors' do
            subject { super().errors }
            it { is_expected.to be_empty }
          end
        end

        describe 'is_error' do
          before do
            @create.call
          end

          subject { @is_error }
          it { is_expected.to be_falsey }
        end

        describe 'created item' do
          before do
            @create.call
          end
          subject do
            @item
          end

          describe '#name' do
            subject { super().name }
            it { is_expected.to eq('テスト10') }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end
        end

        describe 'Item.count' do
          it { expect { @create.call }.to change { Item.count }.by(2) }
        end
      end

      context 'created item with credit card, purchased before the settlement date of the month,' do
        before do
          @create = -> { @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1), action_date: Date.new(2008, 2, 10), name: 'テスト10', amount: 10_000, from_account_id: accounts(:credit4).id, to_account_id: accounts(:expense3).id) }
        end

        let(:credit_item) do
          Item.where(action_date: Date.new(2008, 2, 10),
                     from_account_id: accounts(:credit4).id,
                     to_account_id: accounts(:expense3).id,
                     amount: 10_000,
                     parent_id: nil).find(&:child_item)
        end

        it_should_behave_like 'created itself and credit payment item successfully'

        describe 'created credit item' do
          before do
            @create.call
          end
          subject { credit_item }
          it { is_expected.not_to be_nil }

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end

          describe '#parent_id' do
            subject { super().parent_id }
            it { is_expected.to be_nil }
          end

          describe '#child_item' do
            subject { super().child_item }
            it { is_expected.not_to be_nil }
          end
        end

        describe "child item's count" do
          before do
            @create.call
          end
          subject { Item.where(parent_id: credit_item.id) }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(1) }
          end
        end

        describe 'child item' do
          before do
            @create.call
          end
          subject { Item.where(parent_id: credit_item.id).find { |i| i.child_item.nil? } }

          describe '#child_item' do
            subject { super().child_item }
            it { is_expected.to be_nil }
          end

          describe '#parent_item' do
            subject { super().parent_item }
            it { is_expected.to eq(credit_item) }
          end

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq(Date.new(2008, 2 + credit_relations(:cr1).payment_month, credit_relations(:cr1).payment_day)) }
          end

          describe '#from_account_id' do
            subject { super().from_account_id }
            it { is_expected.to eq(credit_relations(:cr1).payment_account_id) }
          end

          describe '#to_account_id' do
            subject { super().to_account_id }
            it { is_expected.to eq(credit_relations(:cr1).credit_account_id) }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end

          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(Item.where(parent_id: @item.id).first.id) }
          end
        end
      end

      context 'created item with credit card, purchased before the settlement date of the month,' do
        before do
          cr1 = credit_relations(:cr1)
          cr1.settlement_day = 15
          cr1.save!

          @create = lambda {
            @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1),
                                                                       action_date: Date.new(2008, 2, 25),
                                                                       name: 'テスト10', amount: 10_000,
                                                                       from_account_id: accounts(:credit4).id,
                                                                       to_account_id: accounts(:expense3).id)
          }
        end

        let(:credit_item) do
          Item.where(action_date: Date.new(2008, 2, 25),
                     from_account_id: accounts(:credit4).id,
                     to_account_id: accounts(:expense3).id,
                     amount: 10_000, parent_id: nil).find(&:child_item)
        end

        it_should_behave_like 'created itself and credit payment item successfully'

        describe 'created credit item' do
          before do
            @create.call
          end
          subject { credit_item }
          it { is_expected.not_to be_nil }

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end

          describe '#parent_id' do
            subject { super().parent_id }
            it { is_expected.to be_nil }
          end

          describe '#child_item' do
            subject { super().child_item }
            it { is_expected.not_to be_nil }
          end

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq(Date.new(2008, 2, 25)) }
          end
        end

        describe 'child item' do
          before do
            @create.call
          end

          describe 'child item count' do
            subject { Item.where(parent_id: credit_item.id) }

            describe '#count' do
              subject { super().count }
              it { is_expected.to eq(1) }
            end
          end

          describe 'child item' do
            subject { Item.where(parent_id: credit_item.id).first }

            describe '#child_item' do
              subject { super().child_item }
              it { is_expected.to be_nil }
            end

            describe '#parent_id' do
              subject { super().parent_id }
              it { is_expected.to eq(credit_item.id) }
            end

            describe '#id' do
              subject { super().id }
              it { is_expected.to eq(credit_item.child_item.id) }
            end

            describe '#action_date' do
              subject { super().action_date }
              it { is_expected.to eq(Date.new(2008, 3 + credit_relations(:cr1).payment_month, credit_relations(:cr1).payment_day)) }
            end

            describe '#from_account_id' do
              subject { super().from_account_id }
              it { is_expected.to eq(credit_relations(:cr1).payment_account_id) }
            end

            describe '#to_account_id' do
              subject { super().to_account_id }
              it { is_expected.to eq(credit_relations(:cr1).credit_account_id) }
            end

            describe '#amount' do
              subject { super().amount }
              it { is_expected.to eq(10_000) }
            end
          end
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end
          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(Item.where(parent_id: @item.id).first.id) }
          end
        end
      end

      context 'created item with credit card, whose settlement_date == 99,' do
        before do
          @cr1 = credit_relations(:cr1)
          @cr1.payment_day = 99
          @cr1.save!

          @create = lambda {
            @item, @affected_item_ids, @is_error = Teller.create_entry(users(:user1),
                                                                       action_date: Date.new(2008, 2, 10),
                                                                       name: 'テスト10', amount: 10_000,
                                                                       from_account_id: accounts(:credit4).id,
                                                                       to_account_id: accounts(:expense3).id)
          }
        end

        let(:credit_item) do
          Item.where(action_date: Date.new(2008, 2, 10),
                     from_account_id: accounts(:credit4).id,
                     to_account_id: accounts(:expense3).id,
                     amount: 10_000, parent_id: nil).find(&:child_item)
        end

        it_should_behave_like 'created itself and credit payment item successfully'

        describe 'created credit item' do
          before do
            @create.call
          end

          subject { credit_item }
          it { is_expected.not_to be_nil }

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end

          describe '#parent_id' do
            subject { super().parent_id }
            it { is_expected.to be_nil }
          end

          describe '#child_item' do
            subject { super().child_item }
            it { is_expected.not_to be_nil }
          end

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq(Date.new(2008, 2, 10)) }
          end
        end

        describe "child item's count" do
          before do
            @create.call
          end
          subject { Item.where(parent_id: credit_item.id) }

          describe '#count' do
            subject { super().count }
            it { is_expected.to eq(1) }
          end
        end

        describe 'child item' do
          before do
            @create.call
          end
          subject { Item.where(parent_id: credit_item.id).first }

          describe '#child_item' do
            subject { super().child_item }
            it { is_expected.to be_nil }
          end

          describe '#parent_id' do
            subject { super().parent_id }
            it { is_expected.to eq(credit_item.id) }
          end

          describe '#id' do
            subject { super().id }
            it { is_expected.to eq(credit_item.child_item.id) }
          end

          describe '#action_date' do
            subject { super().action_date }
            it { is_expected.to eq(Date.new(2008, 2 + @cr1.payment_month, 1).end_of_month) }
          end

          describe '#from_account_id' do
            subject { super().from_account_id }
            it { is_expected.to eq(@cr1.payment_account_id) }
          end

          describe '#to_account_id' do
            subject { super().to_account_id }
            it { is_expected.to eq(@cr1.credit_account_id) }
          end

          describe '#amount' do
            subject { super().amount }
            it { is_expected.to eq(10_000) }
          end
        end

        describe 'affected_item_ids' do
          before do
            @create.call
          end
          describe 'the number of items' do
            subject { @affected_item_ids }
            it 'has 1 item' do
              expect(subject.size).to eq(1)
            end
          end

          describe 'affected item' do
            subject { @affected_item_ids[0] }
            it { is_expected.to eq(Item.where(parent_id: @item.id).first.id) }
          end
        end
      end
    end
  end
end
