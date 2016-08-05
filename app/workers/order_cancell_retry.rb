class OrderCancellRetry
  @queue = :order_cancell_retry
  
  FIRST_DELAY = 10.minutes
  
  SECOND_DELAY = 60.minutes

  def self.perform
    Order.cancelling.each do |o|
      key = "order_cancell_#{o.id}"
      delay = Time.now - o.updated_at
      if delay < FIRST_DELAY
      elsif delay < SECOND_DELAY
        if $redis.get(key).to_i < 1
          o.send_cancel_to_remote
          $redis.incr(key)
        end
      else
        if $redis.get(key).to_i == 1
          o.send_cancel_to_remote
          $redis.del(key)
        end
      end
    end
  end
end
