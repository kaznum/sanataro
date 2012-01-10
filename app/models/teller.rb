# coding: utf-8
class Teller
  def self.create_entry(args)
    user = args[:user]
    # taggableの問題で、user_idを明示的にしてしないと、tagにuser_idが設定されない
    item = Item.new(args){ |i|
      i.user_id = user.id
    }
    
    affected_items = []
    ActiveRecord::Base.transaction do 
      item.save!
      
      from_item_adj = Item.adjust_future_balance(user, item.from_account_id, item.amount, item.action_date, item.id)
      to_item_adj = Item.adjust_future_balance(user, item.to_account_id, item.amount * (-1), item.action_date, item.id)
      affected_items << from_item_adj unless from_item_adj.nil?
      affected_items << to_item_adj unless to_item_adj.nil?
      
      MonthlyProfitLoss.reflect_relatively(user, item.action_date.beginning_of_month, item.from_account_id, item.to_account_id, item.amount)

      #
      # クレジットカードの処理
      #
      cr = user.credit_relations.find_by_credit_account_id(item.from_account_id)
      unless cr.nil?
        payment_date = credit_payment_date(user, item.from_account_id, item.action_date)
        cr_item, cr_affected_items, is_cr_error =
          create_entry(:name => item.name,
                       :from_account_id => cr.payment_account_id,
                       :to_account_id => item.from_account_id,
                       :amount => item.amount,
                       :action_date => payment_date,
                       :parent_id => item.id,
                       :user => user)
        raise ActiveRecord::RecordInvalid.new(cr_item) if is_cr_error
        unless cr_item.nil?
          item.child_id = cr_item.id
          item.save!
          affected_items << cr_item
          affected_items += cr_affected_items
        end
      end
    end
    return [item, affected_items, false]
  rescue ActiveRecord::RecordInvalid
    return [item, affected_items, true]
  end

  def self.credit_payment_date(user, account_id, date)
    user.accounts.where(id: account_id).first.credit_due_date(date)
  end
  
end
