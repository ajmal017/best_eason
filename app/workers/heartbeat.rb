class Heartbeat
  @queue = :heartbeat

  def self.perform
    send_notice if $redis.scard("pms_cts_heartbeat") >= Setting.pms_cts_heartbeat
    t = Time.now.to_s_full
    $redis.sadd("pms_cts_heartbeat", t)
    OrderStatusPublisher.publish({"requestTime" => t}.to_xml(root: "heartbeat"))
  end

  def self.send_notice
    Caishuo::Utils::Email.deliver(Setting.heartbeat_notifiers[:emails], "#{Rails.env}环境已经连续#{$redis.scard('pms_cts_heartbeat')}次未收到cts的响应，请确认交易系统是否正常工作")
  end

end
