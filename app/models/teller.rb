# coding: utf-8
class Teller
  def self.create_entry(args)
    user = args[:user]
    item = Item.new do |itm|
      itm.user = user
      itm.name = args[:name]
      itm.from_account_id  = args[:from_account_id]
      itm.to_account_id  = args[:to_account_id]
      itm.amount = args[:amount]
      itm.action_date = args[:action_date]
      itm.parent_id = args[:parent_id]
      itm.confirmation_required = args[:confirmation_required]
      itm.tag_list = args[:tag_list]
      itm.user_id = user.id
    end
    
    affected_items = []
    is_error = false
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
        cr_item, cr_affected_items, is_cr_error = create_entry(:name => item.name,
                                                  :from_account_id => cr.payment_account_id,
                                                  :to_account_id => item.from_account_id,
                                                  :amount => item.amount,
                                                  :action_date => payment_date,
                                                  :parent_id => item.id,
                                                  :user => user)
        unless cr_item.nil?
          item.child_id = cr_item.id
          item.save!
          affected_items << cr_item
          affected_items += cr_affected_items
        end
        is_error = is_cr_error
      end
    end
    return [item, affected_items, is_error]
  rescue ActiveRecord::RecordInvalid
    return [item, affected_items, true]
  end

  def self.credit_payment_date(user, account_id, date)
    year = date.year
    month = date.month
    day = date.day

    cr = user.credit_relations.find_by_credit_account_id(account_id)
      unless cr.nil?
        if day <= cr.settlement_day
          payment_month_time = date.beginning_of_month.months_since(cr.payment_month)
        else
          payment_month_time = date.beginning_of_month.months_since(cr.payment_month + 1)
        end

        if cr.payment_day == 99
          payment_time = payment_month_time.end_of_month
        else
          payment_time = Date.new(payment_month_time.year, payment_month_time.month, cr.payment_day)
        end
      else
        return nil
      end
    return payment_time
  end
  
end
