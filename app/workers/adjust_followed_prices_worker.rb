class AdjustFollowedPricesWorker
  @queue = :adjust_followed_prices_worker

  def self.perform
    StockAdjustingFactor.where(ex_divi_date: Date.today).each do |saf|
      saf.adjust!
    end
  end
end
