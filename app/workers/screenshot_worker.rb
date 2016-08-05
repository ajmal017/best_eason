class ScreenshotWorker
  @queue = :screenshot_worker
  
  def self.perform(market)
    Basket.public_finished.where(market: market).select(:id).find_each do |b|
      begin
        BasketMiniChartScreenshotUploader.draw({basket_id: b.id})
      rescue
        sleep 1
      end
    end

    SymbolTopicMaper.store_all
  end

end
