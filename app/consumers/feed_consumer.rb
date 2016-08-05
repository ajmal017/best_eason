class FeedConsumer

  include Sneakers::Worker
  include Trading::AckHelper

  from_queue 'com.caishuo.feeds', :threads => 1, :prefetch => 10, :exchange_arguments => {
      "alternate-exchange" => "caishuox.unroutable"
    },
    :queue_arguments => {
      "x-dead-letter-exchange" => "caishuox.deadletter",
      "x-dead-letter-routing-key" => "com.caishuo.feeds.deadletter"
    }


  # msg
  # 参数:
  # event, 必填 事件类型, 目前支持 news
  # source_id, 必填  源ID, 例如新闻ID
  # source_type, 可选,  源类型(class name) 当同一event类型下对应多态对象时候，必需指定
  def work(msg)
    msg = msg.force_encoding("utf-8")
    switch_handler(msg)
    ack!
  rescue => e
    logger.error e.inspect
    logger.error e.exception
    to_dead_letter!
  end

  # handler切换
  # news: 
  #   {"event":"news","source_id":"55daf1c36b9c9a4d2a000389"}
  # filter:
  #   {"event":"filter","source_id":"filter_lhb"}
  def switch_handler(msg)
    result = $json.decode(msg)
    logger.debug(result)
    MD::FeedHub.add_hub(result['event'], result['source_id'])
  end


end