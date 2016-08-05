module Trading
  
  module AccountValueCreator
    
    def create_account_value
      if has_key?
        begin
          ::AccountValue.find_or_create_by(account_attrs).update_attributes(other_attrs)
        rescue ActiveRecord::RecordNotUnique => e
          ::AccountValue.find_or_create_by(account_attrs).update_attributes(other_attrs)
        end
        create_last_total_cash if (balance? && is_base?) || cash_value?
      end
    end
    
    def cash_key
      {
        trading_account_id: account.id,
        key: "LastTotalCash"
      }
    end
    
    def create_last_total_cash
      ::AccountValue.find_or_initialize_by(cash_key).update_attributes(other_attrs.merge(currency: currency))
    end
    
    def has_key?
      ::AccountValue::TYPES.keys.include?(key.underscore.to_sym)
    end
    
    def account_attrs
      { 
        trading_account_id: account.id,
        key: account_value,
        currency: currency
      }
    end
    
    def account_value
      ::AccountValue::TYPES[key.underscore.to_sym]
    end
    
    def other_attrs
      {
        user_id: account.user_id,
        broker_user_id: account.broker_no,
        value: value.to_d
      }
    end
    
    def account
      @account ||= ::TradingAccount.find_by!(broker_no: account_name)
    end
    
    def is_base?
      currency == "BASE"
    end
    
    def balance?
      "TotalCashBalance" == key
    end
    
    def cash_value?
      "TotalCashValue" == key
    end
    
  end
  
end
