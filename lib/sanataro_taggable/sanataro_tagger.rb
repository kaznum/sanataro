module ActiveRecord
  module Sanataro #:nodoc:
    module Tagger #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def sanataro_tagger(options = {})
          has_many :taggings
          has_many :tags, through: :taggings

          extend ActiveRecord::Sanataro::Tagger::SingletonMethods
          include ActiveRecord::Sanataro::Tagger::InstanceMethods
        end
      end

      module SingletonMethods
      end

      module InstanceMethods
      end
    end
  end
end

