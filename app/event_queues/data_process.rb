class EventQueue::DataProcess < Publisher::Base
  
  binding :data_process
  format :json
  
  # type消息类型(比如halted_stock_fetch停牌股票数据抓取)
  def self.publish(message, opts={})
    return if message.blank? || message[:type].blank?

    super(message, opts.merge({routing_key: "com.caishuo.data_process"}))  
  end

end
