# -*- coding: utf-8 -*-
require 'spec_helper'

describe Tag do
  describe "parse" do
    context "when arg is null, " do
      specify { expect(Tag.parse(nil)).to be_empty }
    end

    context "when arg is a single value, " do
      specify { expect(Tag.parse('abc')).to include('abc') }
      specify { expect(Tag.parse('abc').size).to eq(1) }
    end

    context "when arg is a single value with a space, " do
      specify { expect(Tag.parse('abc ')).to include('abc') }
      specify { expect(Tag.parse('abc ').size).to eq(1) }
    end

    context "when arg is multiple values, " do
      specify { expect(Tag.parse(' abc  def ')).to include('abc') }
      specify { expect(Tag.parse(' abc  def ')).to include('def') }
      specify { expect(Tag.parse(' abc  def ').size).to eq(2) }
    end

    context "when arg is multiple values and some of which are duplicated, " do
      specify { expect(Tag.parse(' abc  def  abc ')).to include('abc') }
      specify { expect(Tag.parse(' abc  def  abc ')).to include('def') }
      specify { expect(Tag.parse(' abc  def  abc ').size).to eq(2) }
    end

    context "when arg is multiple values and some of which are double-quoted, " do
      specify { expect(Tag.parse(' abc  "def hij" ')).to include('abc') }
      specify { expect(Tag.parse(' abc  "def hij" ')).to include('def hij') }
      specify { expect(Tag.parse(' abc  "def jij" ').size).to eq(2) }
    end
  end
end
