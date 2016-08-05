class Sneakers::Queue
  
  #
  # if :use_ssl is configured to true, we use ssl connection
  #
  def subscribe_with_ssl(worker)
    if @opts[:use_ssl]
      @bunny = Bunny.new(@opts[:amqps],
                          :tls_cert => @opts[:tls_cert],
                          :tls_key => @opts[:tls_key],
                          :tls_ca_certificates => @opts[:tls_ca_certificates],
                          :vhost => @opts[:vhost],
                          :heartbeat => @opts[:heartbeat],
                          :logger => Sneakers::logger,
                          :recover_from_connection_close => true)
    else
      @bunny = Bunny.new(@opts[:amqp],
                          :vhost => @opts[:vhost],
                          :heartbeat => @opts[:heartbeat],
                          :logger => Sneakers::logger,
                          :recover_from_connection_close => true)
    end
    @bunny.start

    @channel = @bunny.create_channel
    @channel.prefetch(@opts[:prefetch])

    @exchange = @channel.exchange(@opts[:exchange],
                                   :type => @opts[:exchange_type],
                                   :durable => @opts[:durable], 
                                   :arguments => @opts[:exchange_arguments])

    handler = @handler_klass.new(@channel)

    routing_key = @opts[:routing_key] || @name
    routing_keys = [*routing_key]

    queue = @channel.queue(@name, :durable => @opts[:durable], :arguments => @opts[:queue_arguments])

    routing_keys.each do |key|
      queue.bind(@exchange, :routing_key => key)
    end

    @consumer = queue.subscribe(:block => false, :ack => @opts[:ack]) do | hdr, props, msg | 
      worker.do_work(hdr, props, msg, handler)
    end
    nil
  end

  
  alias_method_chain :subscribe, :ssl
=begin
  alias_method :subscribe_without_ssl, :subscribe
  alias_method :subscribe, :subscribe_with_ssl
=end  
  
end

module Sneakers
  def config
    Sneakers.config    
  end

  def self.config
    return Config if defined?(Config)
    return CONFIG if defined?(CONFIG)
  end
  private

    def self.setup_general_logger!
      if [:info, :debug, :error, :warn].all?{ |meth| config[:log].respond_to?(meth) }
        @logger = config[:log]
      else
        @logger = Logger.new(config[:log], config[:shift_age] || 10, config[:shift_size] || 200*1024*1024)
        @logger.formatter = Sneakers::Support::ProductionFormatter
      end
    end
end
