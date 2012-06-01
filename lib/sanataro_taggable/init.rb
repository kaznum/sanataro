$:.unshift File.dirname(__FILE__)

require 'sanataro_taggable'
require 'sanataro_tagger'

ActiveRecord::Base.send(:include, ActiveRecord::Sanataro::Taggable)
ActiveRecord::Base.send(:include, ActiveRecord::Sanataro::Tagger)

require 'tagging'
require 'tag'
