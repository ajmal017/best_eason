class HistoricalRetryWorker 
  @queue = :historical_retry

  def self.perform

    historical_retry_count = Yahoo::HistoricalRetry.where(date: Date.today).count

    $finance_retry_logger.info("=======#{Time.now.to_s(:full)}======#{historical_retry_count}===============")

    $finance_retry_logger.info("正在同步的历史数据数量======#{$redis.llen('resque:queue:his_sync')}===============")

    # 抓取失败的数量大于10 && 没有正在同步的历史数据 && 当前时间小于12点
    if (historical_retry_count >= 10) && ($redis.llen('resque:queue:his_sync') == 0) && (Time.now.hour <= 13)

      $finance_retry_logger.info("开始同步抓取失败的历史数据")

      base_stock_ids = Yahoo::HistoricalRetry.where(date: Date.today).map(&:base_stock_id).to_a.uniq

      # 删除所有失败的合法股票
      Yahoo::HistoricalRetry.where(date: Date.today).delete_all

      # 记录上次同步失败的所有合法股票ID
      $redis.sadd("historical_retry: #{Date.today.to_s(:db)}", base_stock_ids)

      # 清空redis失败重试次数
      base_stock_ids.each do |base_stock_id|
        $redis.del("historical_retry_times_#{base_stock_id}")
      end

      base_stock_ids.in_groups_of(5).each do |base_ids|
        Yahoo::Historical::Base.new(base_ids).sync
      end

      # 抓取ADJ_CLOSE成功后续任务
      # 当前时间大于11点 && 失败数量小于10 && 正在同步的历史数据为0 && 后续任务今日没有执行过
    elsif (Time.now.hour >= 11) && (historical_retry_count <= 10) && ($redis.llen('resque:queue:his_sync') == 0) && ($redis.get(basket_sync_key).to_i == 0)
      increment_basket_index_execute_counter

      Resque.enqueue(CalculateBasketIndex)
      Resque.enqueue(KlineGenerate)

      $finance_retry_logger.info("=====#{Date.today.to_s(:db)}=====数据抓取成功#{historical_retry_count},后续任务正在执行")
      
      send_notification_email("#{Date.today.to_s(:db)}===数据抓取成功")
    
    elsif (Time.now.hour > 12) && $redis.get(basket_sync_key).to_i == 0

      increment_basket_index_execute_counter

      Resque.enqueue(CalculateBasketIndex)
      Resque.enqueue(KlineGenerate)

      $finance_retry_logger.info("=====#{Date.today.to_s(:db)}=====数据抓取失败#{historical_retry_count},后续任务开始执行")

      send_notification_email("#{Date.today.to_s(:db)}===数据抓取失败#{historical_retry_count}===")
    else

      $finance_retry_logger.info("不符合任何条件")

    end

  end

  # 主题ｉｎｄｅｘ同步次数
  def self.basket_sync_key
    "basket_index:#{Date.today.to_s(:db)}"
  end

  def self.increment_basket_index_execute_counter
    $redis.incr(basket_sync_key)
    $redis.expire(basket_sync_key, 2.day)
  end

  def self.send_notification_email(message)
    ExceptionNotifier.notify_exception(Exception.new, :data => {:payload => message}) rescue nil
  end

end
