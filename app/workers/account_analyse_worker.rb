class AccountAnalyseWorker
  @queue = :account_analysis

  def self.perform(account_id = nil, market = "cn")
    if account_id.present?
      AccountAnalysis.cal(account_id, Date.yesterday)
    else
      # 同步投资行业分布比例
      Investment.sync_sector_ratio
      broker_ids = market == "cn" ? Broker.where(market: market).pluck(:id)
                                  : Broker.where("market <> 'cn'").pluck(:id)
      
      TradingAccount.active.where(broker_id: broker_ids).select(:id).find_each do |account|
        Resque.enqueue(AccountAnalyseWorker, account.id)
      end
    end
  end
end