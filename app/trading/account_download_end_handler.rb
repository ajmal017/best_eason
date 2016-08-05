module Trading
  
  class AccountDownloadEndHandler
    extend Forwardable
    
    def_delegators :account, :first_portfolio_message?
    
    include InitHelper
    
    def account
      @account ||= ::TradingAccount.find_by!(broker_no: account_name)
    end
    
    def perform
      account.update_attributes(portfolioable: true) if first_portfolio_message?
    end
  end
  
end
