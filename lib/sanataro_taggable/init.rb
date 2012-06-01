$:.unshift File.dirname(__FILE__)

ActiveSupport.on_load(:active_record) do
  require 'sanataro_taggable'
  require 'sanataro_tagger'

  ActiveRecord::Base.send(:include, ActiveRecord::Sanataro::Taggable)
  ActiveRecord::Base.send(:include, ActiveRecord::Sanataro::Tagger)

  require 'tagging'
  require 'tag'
end

