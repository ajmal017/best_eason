class Configs
  class << self
  	# 删除多少小时前的未确认订单
    def unconfirmed_orders_hours
      hours = $redis.hget("configs", "unconfirmed_orders_hours")
      hours.to_i > 0 ? hours.to_i : 720 
    end

    def set_unconfirmed_orders_hours(hours)
      hours = hours.to_i > 0 ? hours : 720
      $redis.hset("configs", "unconfirmed_orders_hours", hours)
    end
  end
end
