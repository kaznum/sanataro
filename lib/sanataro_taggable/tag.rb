class Tag < ActiveRecord::Base
  has_many :taggings
  validates_presence_of :name

  def self.parse(list)
    tag_names = []
    return tag_names if list.blank?

    list.gsub!(/\"(.*?)\"\s*/) { tag_names << $1; "" }
    list.gsub!(/,/, " ")
    tag_names.concat(list.split(/\s/))
    tag_names = tag_names.delete_if { |t| t.empty? }
    tag_names = tag_names.map! { |t| t.downcase }
    tag_names = tag_names.uniq

    tag_names
  end

  def to_s
    name
  end
end
