class BasketIndexQueue
  @queue = :basket_index
  
  def self.perform(basket_id, date_str)
    date = Date.parse(date_str)
    BasketIndex.record_index(basket_id, date)
    basket = Basket.find_by_id(basket_id)
    if basket
      SyncBasketRetFromPtAccount.perform(basket.id) if basket.shipan?

      basket.calculate_returns
      basket.set_bullish_percent
      basket.set_hot_score
      basket.update_orders_statistics
    end
  end
end