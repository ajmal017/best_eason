class StockReminderLoop
  @queue = :reminder_loop

  def self.perform
    # 清除相关keys
    StockReminder.remove_keys!

    # 创建对应keys
    StockReminder.loop_create
  end
end
