class SyncBasketRetFromPtAccount
  @queue = :sync_basket_ret_from_pt_account

  # 暂时只考虑A股实盘大赛
  def self.perform(basket_id)
    exchange = Exchange::Base.by_area("cn")
    return "非交易日" unless exchange.workday?

    basket = Basket.normal.finished.find(basket_id)
    return false if basket.blank?

    account = basket.pt_account
    return false if account.blank?

    prev_workday = exchange.previous_workday
    
    if account.out?
      basket_rank = BasketRank.where(trading_account_id: account.id, basket_id: basket.id).last
      total_ret = basket_rank.ret/100 rescue 0
    else
      total_ret = basket.shipan_total_ret_percent/100 rescue 0
    end
    today_index = 1000 * (1 + total_ret)
    basket_index = BasketIndex.where(basket_id: basket.id, date: exchange.today).last
    basket_index.update(index: today_index)
  end
end