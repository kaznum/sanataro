# -*- coding: utf-8 -*-
#require 'digest/sha1'
class CommonUtil
  class << self
    def separate_by_comma(number)
      number_i = number.to_i
      is_negative = false
      if number_i < 0
        is_negative = true
        number_i = (-1) * number_i
      end
      ret_str = number_i.to_s.reverse.gsub( /(\d{3})/, "\\1," ).chomp( "," ).reverse
      ret_str = '-' + ret_str if is_negative
      return ret_str
    end

    def remove_comma(str)
      if str.nil?
        return nil
      end

      return str.to_s.gsub(/,/, '')
    end

    def check_password(str, encpass)
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
