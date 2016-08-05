require 'account_value_creator'

module Trading
  
  class AccountSummaryHandler
    
    include InitHelper
    
    include AccountValueCreator
    
    def perform
      create_account_value
    end
    
  end #AccountSummaryHandler
  
end #Trading