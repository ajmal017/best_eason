class ReconcileRequestCts < ReconcileRequestList
  def self.publish
    self.all.map(&:publish)
  end
  
  def publish
     publish! if can_publish?
  end
  
  def publish!
    trading_account.request_execution if trading_account.present?
  end

end
