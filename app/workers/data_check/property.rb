class DataCheck::Property
  @queue = :data_check
  
  def self.perform(market)
    case market.to_s
    when "cn"
      ids, date, notice = TradingAccountPassword.active.map(&:id), Date.today, "A股"
    when "foreign"
      ids, date, notice = TradingAccountEmail.active.map(&:id), Date.yesterday, "美股港股"
    when "pt"
      ids, date, notice = TradingAccountPT.active.map(&:id), Date.yesterday, "实盘大赛"
    end
    
    synced_count = UserDayProperty.where(trading_account_id: ids, date: date).count
    msg = "数据检查:#{notice}账户净值#{date.to_s(:db)}同步数量#{synced_count}"

    DataCheck::Notice.perform(msg)
  end

end
