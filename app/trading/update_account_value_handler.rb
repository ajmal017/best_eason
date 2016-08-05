require 'account_value_creator'

module Trading
  
  class UpdateAccountValueHandler
    
    include InitHelper
    
    include AccountValueCreator
    
    def perform
      key_is_exchange_rate? ? update_base_currency : create_account_value
    end
    
    def key_is_exchange_rate?
      key.underscore.to_sym == :exchange_rate
    end
    
    def update_base_currency
      account.update(base_currency: currency) if !is_base? && exchange_rate_is_1?
      log_exchange_rate
    end
    
    def log_exchange_rate
      ::ExchangeRate.find_or_initialize_by(currency: currency, trading_account_id: account.id).update(value: value, account_name: account_name)
    end
    
    def exchange_rate_is_1?
      value.to_d.round(10) == 1.0
    end
    
  end #UpdateAccountValueHandler
  
end #Trading
