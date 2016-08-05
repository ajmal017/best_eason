auto_required_paths = %W(app/models/activity app/validators app/workers app/caches lib/ lib/core_ext app/crawlers app/event_queues app/apis app/models/md app/models/md/feed app/consumers)

# 自动加载目录
auto_required_paths.each do |d|
  Dir["#{Rails.root}/#{d}/*.rb"].each {|p| require p}
end

require "#{Rails.root}/app/trading/trading.rb"

# 加载xmlsimple处理xml转hash
require 'xmlsimple'
