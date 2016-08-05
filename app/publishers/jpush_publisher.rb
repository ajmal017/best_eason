class JpushPublisher < Publisher::Base

  binding :jpush_queue
  format  :json

  def self.publish(message, opts={})
    super(message, opts.merge({routing_key: "com.caishuo.jpush"}))
  end

end
