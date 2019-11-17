# frozen_string_literal: true

$LOAD_PATH.unshift File.dirname(__FILE__)

ActiveSupport.on_load(:active_record) do
  require 'sanataro_taggable'
  require 'sanataro_tagger'

  ActiveRecord::Base.prepend ActiveRecord::Sanataro::Taggable
  ActiveRecord::Base.prepend ActiveRecord::Sanataro::Tagger

  require 'tagging'
  require 'tag'
end
