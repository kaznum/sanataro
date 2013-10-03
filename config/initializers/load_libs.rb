$LOAD_PATH.unshift File.dirname(__FILE__)

require File.expand_path(File.join(Rails.root, 'lib', 'common_util'))
require File.expand_path(File.join(Rails.root, 'lib', 'active_record_ext'))
require File.expand_path(File.join(Rails.root, 'lib', 'array_ext'))
require File.expand_path(File.join(Rails.root, 'lib', 'date_ext'))
