class AccountStatusesController < ApplicationController
  before_action :required_login
  def show
    @account_statuses = _account_status
  end

  private

  def _account_status
    retval = known_account_statuses_on(today)
    append_unknown_amount_on(today, retval)

    retval
  end

  def known_account_statuses_on(date)
    retval = {}
    %i[bankings incomes expenses].each do |type|
      retval[type] = @user.send(type).active.map { |a| [a, a.status_of_the_day(date)] }
    end
    retval
  end

  def append_unknown_amount_on(date, statuses)
    unknown_total = unknown_amount_on(date)
    return if unknown_total == 0

    typed_accounts = unknown_total < 0 ? :expenses : :incomes
    unknown_account = @user.send(typed_accounts).build do |a|
      a.name = I18n.t('label.unknown')
      a.order_no = 999_999
    end
    statuses[typed_accounts] << [unknown_account, unknown_total.abs]
  end

  def unknown_amount_on(date)
    from = date.beginning_of_month
    to = date
    @user.items.where(from_account_id: -1).action_date_between(from, to).sum(:amount)
  end
end
