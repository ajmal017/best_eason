class DailyCiticsAudit
  @queue = :citics_audit

  def self.perform
    TradingAccountPassword.deliver_to_citics 
  end

end
