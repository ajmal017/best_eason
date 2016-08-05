#!/usr/bin/env ruby

require 'rubygems'
require 'redis'

redis = Redis.new

puts "******正在同步*****"
redis.smembers("resque:queues").each do |name|
	puts [name, redis.llen("queue:#{name}")].join(',')
end


