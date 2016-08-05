class ReadjustBasketWorker
  @queue = :readjust_basket

  def self.perform(basket_id)
    BasketAdjustChecking.execute(basket_id)
  end

end