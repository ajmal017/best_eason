class ArchiveUserProfit
  @queue = :daily_archive
  
  def self.perform(date = nil)
    date ||= Date.yesterday

    TradingAccount.active.find_each do |account|
      begin
        UserDayProperty.ib_sync(account) if account.is_a?(TradingAccountEmail)
        UserProfit.sync(account, date)
        UserStockProfit.calculate(account, date)
      rescue Exception => e
        Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "收益worker出错: #{account.id} #{e.message}")
        next
      end
      
    end
  end

end
