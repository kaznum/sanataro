module ActiveRecord
  module Sanataro #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def sanataro_taggable(options = {})
          has_many :taggings, as: :taggable, dependent: :destroy
          has_many :tags, through: :taggings
          # TODO
          # On JRuby and PosgreSQL, the following statement does not work well
          # because of the restriction where distinct and order clause needs that the columns which is used in them in select clause.
          # scope :tagged_with, lambda { |tag| ids = includes(:tags).where("tags.name = ?", tag).references(:tags) }
          scope :tagged_with, lambda { |tag|
            ids = includes(:tags).where("tags.name = ?", tag).references(:tags).pluck(:id)
            where(id: ids)
          }

          after_save :update_tags

          extend ActiveRecord::Sanataro::Taggable::SingletonMethods
          include ActiveRecord::Sanataro::Taggable::InstanceMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
        def tag_list
          @tag_list ||= tags.map(&:name).map(&:downcase).sort.join(" ")
        end

        def tag_list=(str)
          @tag_list = Tag.parse(str).sort.join(" ")
        end

        def update_tags
          stored_tags = tags
          if tag_list != stored_tags.map(&:name).map(&:downcase).sort.join(" ")
            taggings.where(user_id: user_id).destroy_all
            Tag.parse(@tag_list).each do |name|
              tag = Tag.find_or_create_by(name: name)
              tagging = self.taggings.new { |t| 
                t.user_id = self.user_id
                t.tag_id = tag.id
              }
              tagging.save!
            end
          end
          @tag_list = nil
        end
      end
    end
  end
end
