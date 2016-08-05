class BasketAdjustLogsGenerator
  @queue = :basket_adjust_logs_generator

  def self.perform(basket_adjustment_id)
  	ba = BasketAdjustment.find_by_id(basket_adjustment_id)
  	retry_times = 0
    while ba.blank? && retry_times < 4 do
      retry_times += 1
      sleep(0.5)
      ba = BasketAdjustment.find_by_id(basket_adjustment_id)
    end
    ba.generate_logs
  end

end