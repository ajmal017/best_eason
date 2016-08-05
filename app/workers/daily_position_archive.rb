class DailyPositionArchive
  @queue = :daily_archive

  def self.perform(exchange_name)
    case exchange_name.downcase

    when "us"
      PositionArchive.daily_generate(:us, Date.yesterday)
      PortfolioArchive.daily_generate(exchange_name, Date.yesterday)
    when "sehk"
      PositionArchive.daily_generate(:hk, Date.yesterday)
      PortfolioArchive.daily_generate(exchange_name, Date.yesterday)
    when "cn"
      PositionArchive.daily_generate(:cn, Date.yesterday)
      PositionArchive.update_archived_new_stock_close_prices(Date.yesterday)
    end

  end

end
