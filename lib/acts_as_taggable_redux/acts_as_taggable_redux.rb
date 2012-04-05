require 'acts_as_taggable'
require 'acts_as_tagger'

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Taggable)
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Tagger)

require 'tagging'
require 'tag'
