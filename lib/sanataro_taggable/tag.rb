# frozen_string_literal: true

class Tag < ActiveRecord::Base
  has_many :taggings
  validates_presence_of :name

  def self.parse(tags_str)
    tag_names = []
    return tag_names if tags_str.blank?

    tags_str = tags_str.gsub(/\"(.*?)\"\s*/) do
      tag_names << Regexp.last_match(1)
      ''
    end
    (tag_names | tags_str.gsub(/,/, ' ').split(/\s/)).map(&:presence).compact.map(&:downcase).uniq
  end

  def to_s
    name
  end
end
