class LogEraser
  @queue = :log_eraser

  def self.perform
    AdminLog.one_month_ago.delete_all
  end
end
