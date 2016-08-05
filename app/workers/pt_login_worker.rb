class PTLoginWorker
  @queue = :pt_login
  
  def self.perform(trading_account_id)
    ta = TradingAccount.find(trading_account_id)
    ta.login('tac123456')
  end
end
