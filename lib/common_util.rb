# -*- coding: utf-8 -*-
class CommonUtil
  class << self
    def remove_comma(str)
      if str.nil?
        return nil
      end
      str.to_s.gsub(/,/, '')
    end

    def correct_password?(str, encpass)
      if str.nil? || encpass.nil?
        return false
      else
        return Digest::SHA1.hexdigest(str) == encpass
      end
    end

    def crypt(str)
      return Digest::SHA1.hexdigest(str)
    end

    def valid_combined_year_month?(year_month)
      if year_month.blank? || year_month !~ /^([1-9][0-9]{3})([0-9]{2})$/
        return false
      end

      year = Regexp.last_match(1).to_i
      month = Regexp.last_match(2).to_i
      if month < 1 || 12 < month
        return false
      end
      true
    end

    def get_year_month_from_combined(str)
      str =~ /^([1-9][0-9]{3})([0-9]{2})$/
      [Regexp.last_match(1).to_i, Regexp.last_match(2).to_i]
    end
  end

end
