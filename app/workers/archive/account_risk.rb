class Archive::AccountRisk
  @queue = :daily_archive
  
  # area cn foreign
  def self.perform
    TradingAccount.active.each do |account|
      if account.is_a?(TradingAccountPassword)
        date = Date.today
      end
      
      if account.is_a?(TradingAccountEmail)
        date = Time.now.hour <= 8 ? Date.yesterday : Date.today
      end
      
      AccountPositionRisk.update_score(account.id, date)
    end
  end

end
