#
# check the difference between monthly profit losses and items
#
# example: RAILS_ENV=production rails runner 'eval(IO.readlines("script/monthly_profit_loss_checker.rb").join)'
#
User.all.each do |u|
  u.monthly_profit_losses.each do |mpl|
    month_from = mpl.month.beginning_of_month
    month_to = mpl.month.end_of_month

    items_of_terms = u.items.where(:action_date => month_from..month_to)
    amount_from = items_of_terms.where(:from_account_id => mpl.account_id).sum(:amount) || 0
    amount_to = items_of_terms.where(:to_account_id => mpl.account_id).sum(:amount) || 0

    amount = amount_to - amount_from

    if mpl.amount != amount
      puts "user: #{u.id}, #{month_from}, Account: #{mpl.account_id}:#{Account.find(mpl.account_id).name}, MPL: #{mpl.amount}, REAL: #{amount}"
    end
  end
end
