# coding: utf-8
class Teller
  def self.create_entry(args)
    user = args[:user]
    # taggableの問題で、user_idを明示的にしてしないと、tagにuser_idが設定されない
    item = Item.new(args){ |i|
      i.user_id = user.id
    }
    
    ActiveRecord::Base.transaction do 
      item.save!
    end
    affected_items = []
    affected_items << item.child_item if item.child_item

    adj_scope = user.items.where("action_date > ?", item.action_date).where(from_account_id: -1)
    from_adj = adj_scope.where(to_account_id: item.from_account_id).order(:action_date).first
    to_adj = adj_scope.where(to_account_id: item.to_account_id).order(:action_date).first
    affected_items << from_adj if from_adj
    affected_items << to_adj if to_adj
    
     return [item, affected_items, false]
  rescue ActiveRecord::RecordInvalid
    return [item, affected_items, true]
  end

  def self.credit_payment_date(user, account_id, date)
    user.accounts.where(id: account_id).first.credit_due_date(date)
  end
end
