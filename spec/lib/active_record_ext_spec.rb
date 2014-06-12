# -*- coding: utf-8 -*-
require 'spec_helper'

describe ActiveRecordExt do
  describe "LIKE clause" do
    subject { User.arel_table[:name].matches("%my!%name%").to_sql }
    it { is_expected.to match /\s+ESCAPE '!'$/ }
  end

  describe "NOT LIKE clause" do
    subject { User.arel_table[:name].does_not_match("%my!%name%").to_sql }
    it { is_expected.to match /\s+ESCAPE '!'$/ }
  end
end
