# DEPRECATED CLASS
class OrderPublisher

  def self.publish(message)
    ensure_connection! unless connected?
    exchange = channel.fanout("caishuox.fanout", durable: true, arguments: { "alternate-exchange" => "caishuox.unroutable"})
    queue1 = channel.queue("com.unicorn.cts", durable: true, :arguments => {"x-dead-letter-exchange" => "caishuox.deadletter", "x-dead-letter-routing-key" => "com.unicorn.cts.deadletter"})
    queue2 = channel.queue("com.caishuo.orderstatus", durable: true, :arguments => {"x-dead-letter-exchange" => "caishuox.deadletter", "x-dead-letter-routing-key" => "com.caishuo.orderstatus.deadletter"})
    queue1.bind(exchange)
    queue2.bind(exchange)

    Rails.logger.info message.inspect
    exchange.publish(message, content_type: "text/plain", content_encoding: "utf-8", persistent: true)
  end

  def self.channel
    @channel
  end

  def self.ensure_connection!
    @bunny = Bunny.new(Setting.bunny.symbolize_keys)
    @bunny.start
    @channel = @bunny.create_channel
  end

  def self.connected?
    @bunny && @bunny.connected?
  end
end