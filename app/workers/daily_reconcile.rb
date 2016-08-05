class DailyReconcile
  @queue = :daily_reconcile
  
  def self.perform
    UserBinding.request_execution
  end
  
end
