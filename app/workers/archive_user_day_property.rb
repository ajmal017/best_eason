class ArchiveUserDayProperty
  @queue = :daily_archive
  
  def self.perform
    TradingAccountPassword.active.find_each do |account|
      UserDayProperty.cn_sync(account)
    end
  end

end
