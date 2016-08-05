class RequestFundamental
  @queue = :request_fundamental

  def self.perform
    IbFundamental.request
  end
end
