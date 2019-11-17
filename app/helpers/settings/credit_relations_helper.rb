# frozen_string_literal: true

module Settings::CreditRelationsHelper
  def localize_relative_month(relative_month)
    CreditRelation::PAYMENT_MONTHS.find { |pm| pm[1] == relative_month }[0]
  end
end
