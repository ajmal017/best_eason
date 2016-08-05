class AccountRankWorker
  @queue = :account_rank_worker

  # TODO: 美东时间的处理
  def self.perform(account_id = nil, force_clear_cache = false)
    clear_account_ranks_cache && return if force_clear_cache

    if account_id.blank?
      Setting.trading_account.sim.each do |market, master_account|
        next unless Exchange::Base.by_area(market).workday?
        broker = Broker.find_by_master_account(master_account)
        next unless broker

        TradingAccountSim.where(broker_id: broker.id).select(:id).find_each do |account|
          Resque.enqueue(AccountRankWorker, account.id)
        end
      end
    else
      TradingAccountSim.find_by(id: account_id).try(:cal_profit_percents)
      clear_account_ranks_cache
    end
  end

  def self.clear_account_ranks_cache
    if tasks_size <= 1
      $redis.keys("#{AccountRank::CACHE_KEY_PREFIX}*").map do |key|
        $redis.del(key)
      end
    end
  end

  def self.tasks_size
    Resque.size(instance_variable_get("@queue"))
  end
end
