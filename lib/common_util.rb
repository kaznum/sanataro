# frozen_string_literal: true

class CommonUtil
  class << self
    def remove_comma(str)
      return nil if str.nil?

      str.to_s.gsub(/,/, '')
    end

    def correct_password?(str, encpass)
      return false if str.nil? || encpass.nil?

      Digest::SHA1.hexdigest(str) == encpass
    end

    def crypt(str)
      Digest::SHA1.hexdigest(str)
    end

    def valid_combined_year_month?(year_month)
      return false if year_month.blank? || year_month !~ /^([1-9][0-9]{3})([0-9]{2})$/

      _ = Regexp.last_match(1).to_i
      month = Regexp.last_match(2).to_i

      month.in? 1..12
    end

    def get_year_month_from_combined(str)
      str =~ /^([1-9][0-9]{3})([0-9]{2})$/
      [Regexp.last_match(1).to_i, Regexp.last_match(2).to_i]
    end
  end
end
