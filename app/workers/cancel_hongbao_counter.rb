class CancelHongbaoCounter
  @queue = :cancel_hongbao_counter
  
  def self.perform(date = nil)
    trading_accounts = TradingAccount.arel_table
    user_ids = TradingAccount.select(:user_id).where(trading_accounts[:trading_since].lteq(30.days.ago.to_date)).pluck(:user_id)
    Counter.where(user_id: user_ids, unread_hongbao_count: 1).update_all(unread_hongbao_count: 0)
  end

end
