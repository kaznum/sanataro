class Tag < ActiveRecord::Base
  has_many :taggings
  validates_presence_of :name

  def self.parse(list)
    tag_names = []
    return tag_names if list.blank?

    list.gsub!(/\"(.*?)\"\s*/) do
      tag_names << $1
      ""
    end
    tag_names.concat(list.gsub(/,/, " ").split(/\s/)).delete_if { |t| t.empty? }.map(&:downcase).uniq
  end

  def to_s
    name
  end
end
