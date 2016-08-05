class OrderStatusPublisher < Publisher::Base

  binding :cts

  def self.publish(message, opts={})
    super(message, opts)
  end


end