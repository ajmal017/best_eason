class PortfolioRequest
  @queue = :portfolio_request

  def self.perform(id)
    ub = UserBinding.find_by(id: id)
    if ub
      ub.request_account_value
      ub.request_portfolio
    end
  end
end
