before_fork do
  Sneakers::logger.warn " ** Worker: Disconnect from the database ** "
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect! and ActiveRecord::Base.connection_pool.disconnect!
end


after_fork do
  Sneakers::logger.warn " !! Worker: Reconnect to the database !! "
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end