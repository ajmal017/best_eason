module Trading
  module DetailAttrs
    def key_attrs
      { exec_id: exec_id }
    end
    
    def shared_attrs
      {
        exchange: exchange,
        currency: currency,
        symbol: symbol, 
        contract_id: contract_id, 
        account_name: account_name, 
        avg_price: avg_price, 
        cum_quantity: cum_quantity, 
        exec_exchange: exec_exchange,
        perm_id: perm_id,
        price: price, 
        shares: shares, 
        side: side,
        time: time, 
        ev_rule: ev_rule,
        ex_multiplier: ex_multiplier,
        ib_order_id: order_id,
        user_id: @account.user_id,
        trading_account_id: @account.id,
        stock_id: @stock.id
      }
    end
  end
end
