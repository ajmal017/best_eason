class JpushConsumer

  include Sneakers::Worker
  include Trading::AckHelper

  from_queue 'com.caishuo.jpush', :threads => 1, :prefetch => 10, :exchange_arguments => {
    "alternate-exchange" => "caishuox.unroutable"
  }

  def work(msg)
    jp(JSON.parse(msg))
    ack!
  rescue => e
    logger.error e.inspect
    logger.error e.exception
    to_dead_letter!
  end

  def jp(msg)
    case msg["type"]
    when "alias"
      $jp.send_by_alias(msg["alias"], alert: msg["content"], type: msg["mentionable_type"], id: msg["mentionable_id"])
    when "broadcast"
      $jp.send_broadcast(alert: msg["content"], type: msg["mentionable_type"], id: msg["mentionable_id"])
    else
    end
  end


end
