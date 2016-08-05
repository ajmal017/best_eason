class UnbindTradingAccount
  @queue = :account

  # 目前只有a股券商解除绑定的适合才会调用,美股待定
  def self.perform(trading_account_id)
    Position.where(trading_account_id: trading_account_id).delete_all
    PositionArchive.where(trading_account_id: trading_account_id).delete_all
    
    AccountValue.where(trading_account_id: trading_account_id).delete_all
    AccountValueArchive.where(trading_account_id: trading_account_id).delete_all
    
    UserDayProperty.where(trading_account_id: trading_account_id).delete_all
    UserProfit.where(trading_account_id: trading_account_id).delete_all
    
    Portfolio.where(trading_account_id: trading_account_id).delete_all
    PortfolioArchive.where(trading_account_id: trading_account_id).delete_all
    
    Order.where(trading_account_id: trading_account_id).delete_all
    OrderDetail.where(trading_account_id: trading_account_id).delete_all
    ExecDetail.where(trading_account_id: trading_account_id).delete_all
    
    IbPosition.where(trading_account_id: trading_account_id).delete_all
    OrderLog.where(trading_account_id: trading_account_id).delete_all
    ReconcileRequestList.where(trading_account_id: trading_account_id).delete_all
    ExchangeRate.where(trading_account_id: trading_account_id).delete_all

    AccountRank.where(trading_account_id: trading_account_id).delete_all
  end

end
