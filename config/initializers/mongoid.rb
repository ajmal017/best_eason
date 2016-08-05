Mongoid.logger = Logger.new("#{Rails.root}/log/mongodb.log")
Mongoid.logger.level = Rails.env.production? ? Logger::WARN : Logger::DEBUG