cd `dirname "${0}"`/../
#GEM_HOME=/opt/gems/rubygems RUBYLIB=/opt/gems/lib PATH=/opt/gems/bin:/opt/gems/rubygems/bin:$PATH /usr/bin/ruby script/runner -e production 'eval(IO.readlines("script/clear_session.rb").join)'

RAILS_ENV=production GEM_HOME=/opt/gems/rubygems RUBYLIB=/opt/gems/lib PATH=/opt/gems/bin:/opt/gems/rubygems/bin:$PATH rake db:sessions:clear

