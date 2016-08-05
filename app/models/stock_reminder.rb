class StockReminder < ActiveRecord::Base

  REMINDER_TYPES = %w[ up down scale ]

  belongs_to :user
  belongs_to :stock, class_name: "BaseStock", foreign_key: :stock_id

  after_save :create_redis_key
  after_save :bind_mq, if: -> { reminder_value > 0 }
  after_destroy :remove_redis_key
  after_destroy :remove_mq_binding

  def create_redis_key
    type_key.each do |key|
      $redis.hdel "stock_reminder:#{stock_id}", "#{reminder_value_was}_#{key}_#{user_id}"
      if reminder_value > 0
        $redis.hset "stock_reminder:#{stock_id}", "#{reminder_value}_#{key}_#{user_id}", 1
      end
    end
  end

  def remove_redis_key
    type_key.each do |key|
      $redis.hdel "stock_reminder:#{stock_id}", "#{reminder_value}_#{key}_#{user_id}"
    end
  end

  private

  def type_key
    [
      case reminder_type
      when "up"
        "+"
      when "down"
        "-"
      when "scale"
        ["%+", "%-"]
      end
    ].flatten
  end

  def self.loop_create
    # 清除退市股票的股价提醒
    clear_delisting

    StockReminder.all.each(&:create_redis_key)
    bind_mq(StockReminder.distinct(:stock_id).select(:stock_id).map(&:stock_id))
  end

  def self.clear_delisting
    StockReminder.all.includes(:stock).select{|sr| sr.stock.trading_delist? }.each(&:destroy)
  end

  def self.remove_keys!
    keys = $redis.keys("stock_reminder:*")
    $redis.del(keys) if keys.present?
    unbind_mq(keys.map{|key| key.split(':')[-1] })
  end

  def remove_mq_binding
    self.class.unbind_mq(stock_id) if self.class.where(stock_id: stock_id).count == 0
  end

  def self.unbind_mq(*stock_ids)
    stock_ids.flatten!
    conn = Bunny.new(Setting.bunny.symbolize_keys)
    conn.start
    ch = conn.create_channel
    q  = ch.queue('com.caishuo.stock_reminder', durable: true)
    events_exchange = ch.topic('events', durable: !Rails.env.production?)
    result = stock_ids.map do |stock_id|
      q.unbind(events_exchange, :routing_key => "stocks.realtime.#{stock_id}")
    end
    conn.stop
    return result
  end

  def self.bind_mq(*stock_ids)
    stock_ids.flatten!
    conn = Bunny.new(Setting.bunny.symbolize_keys)
    conn.start
    ch = conn.create_channel
    q  = ch.queue('com.caishuo.stock_reminder', durable: true)
    events_exchange = ch.topic('events', durable: !Rails.env.production?)
    result = stock_ids.map do |stock_id|
      q.bind(events_exchange, :routing_key => "stocks.realtime.#{stock_id}")
    end
    conn.stop
    return result
  end

  def bind_mq
    self.class.bind_mq(stock_id)
  end
end
