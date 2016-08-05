class RefreshTradingCashWorker
  @queue = :refresh_trading_cash_worker

  def self.perform(id)
    account = TradingAccount.find(id)
    account.refresh_cash
  end
end
