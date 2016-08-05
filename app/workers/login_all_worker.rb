class LoginAllWorker
  @queue = :login_all
  
  def self.perform
    RestClient.trading.pt.login_all
  end
end
