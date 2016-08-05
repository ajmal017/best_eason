module TestCaseDataHelpers
  def order_details_attributes(basket)
    order_details_attributes = {}
    basket.stocks.each_with_index do |stock, index|
      od_attrs = {
        index => {
          base_stock_id: stock.id, est_shares: 1000, est_cost: rand(100..1000), 
          symbol: stock.ib_symbol
        }
      }
      order_details_attributes.merge!(od_attrs)
    end
    order_details_attributes
  end
  
  def order_status_basket_message(order_id)
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><basket>  <basketId>4f643322-3022-4b18-a3eb-a9c5d47c1b27:#{order_id}</basketId>  <expiry>2014-08-22 07:09:32 UTC</expiry>  <advAccount>DI186927</advAccount>  <subAccount>DU186929</subAccount>  <order>    <symbol>AAPL</symbol>    <exchange>NASDAQ</exchange>    <price>248.9301</price>    <size>0</size>  </order>  <order>    <symbol>YHOO</symbol>    <exchange>NASDAQ</exchange>    <price>72.86</price>    <size>0</size>  </order> </basket>"
  end
  
  def order_status_order_not_exist
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><xxx>  <basketId>34643322-3022-4b18-a3eb-a9c5d47c1b27</basketId>  <expiry>2014-08-22 07:09:32 UTC</expiry>  <advAccount>DI186927</advAccount>  <subAccount>DU186929</subAccount>  <order>    <symbol>AAPL</symbol>    <exchange>NASDAQ</exchange>    <price>248.9301</price>    <size>0</size>  </order>  <order>    <symbol>YHOO</symbol>    <exchange>NASDAQ</exchange>    <price>72.86</price>    <size>0</size>  </order> </xxx>"
  end
  
  def order_status_other_message
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?><xxx>  <basketId>4f643322-3022-4b18-a3eb-a9c5d47c1b27</basketId>  <expiry>2014-08-22 07:09:32 UTC</expiry>  <advAccount>DI186927</advAccount>  <subAccount>DU186929</subAccount>  <order>    <symbol>AAPL</symbol>    <exchange>NASDAQ</exchange>    <price>248.9301</price>    <size>0</size>  </order>  <order>    <symbol>YHOO</symbol>    <exchange>NASDAQ</exchange>    <price>72.86</price>    <size>0</size>  </order> </xxx>"
  end
  
  def exec_details_hash(basket_id, order_id)
    {"subAccount"=>"DU186929", "exec"=>[
          {"type"=>"API", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.54", "cumQuantity"=>"1000", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ece.01.01", "orderId"=>"10000048", "permId"=>"1008023197", "price"=>"15.54", "shares"=>"1000", "side"=>"SLD", "time"=>"20140819  01:04:24", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"API", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"YHOO", "contractId"=>"12150121", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"1000", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed1.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"1000", "side"=>"BOT", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"TWS", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"400", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed2.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"400", "side"=>"BOT", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"TWS", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"200", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed3.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"200", "side"=>"SLD", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"}
           ],
           "commissionReport" => [
             { commission: 22.03, currency: "HKD", exec_id: "0000f0e6.53f26ece.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 },
             { commission: 22.05, currency: "HKD", exec_id: "0000f0e6.53f26ed1.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 }
           ]
    }
  end
  
  def new_exec_details_hash(basket_id, order_id)
    {"subAccount"=>"DU186929", "exec"=>[
          {"type"=>"API", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.54", "cumQuantity"=>"1000", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ece.01.01", "orderId"=>"10000048", "permId"=>"1008023197", "price"=>"15.54", "shares"=>"1000", "side"=>"BOT", "time"=>"20140819  01:04:24", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"API", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"YHOO", "contractId"=>"12150121", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"1000", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed1.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"1000", "side"=>"BOT", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"TWS", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"400", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed2.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"400", "side"=>"BOT", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"},
           {"type"=>"TWS", "basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "currency" => "USD", "accountName"=>"DU186929", "avgPrice"=>"15.52", "cumQuantity"=>"200", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ed3.01.01", "orderId"=>"10000053", "permId"=>"1008023202", "price"=>"15.52", "shares"=>"200", "side"=>"SLD", "time"=>"20140819  01:05:15", "evRule"=>"null", "exMultiplier"=>"0.0"}
           ],
           "commissionReport" => [
             { commission: 22.03, currency: "HKD", exec_id: "0000f0e6.53f26ece.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 },
             { commission: 22.05, currency: "HKD", exec_id: "0000f0e6.53f26ed1.01.01", realized_pnl: "1.7976931348623157E308", yield: "1.7976931348623157E308", yield_redemption_date: 0 }
           ]
    }
  end
  
  def exec_details_exec_hash
    {"subAccount"=>"DU186929", "exec"=>
              {"type"=>"API", "basketId"=>"4f643322-3022-4b18-a3eb-a9c5d47c1b27", "exchange"=>"SEHK", "symbol"=>"AAPL", "contractId"=>"12150119", "accountName"=>"DU186929", "avgPrice"=>"15.54", "cumQuantity"=>"1000", "execExchange"=>"SEHK", "execId"=>"0000f0e6.53f26ece.01.01", "orderId"=>"10000048", "permId"=>"1008023197", "price"=>"15.54", "shares"=>"1000", "side"=>"BOT", "time"=>"20140819  01:04:24", "evRule"=>"null", "exMultiplier"=>"0.0"}
    }
  end
  
  def portfolio_hash
    {"exchange" => 'NASDAQ', "symbol" => 'AAPL', "contractId" => 10041, "position" => 80, "marketPrice" => 7.32005, "marketValue" => 585.6, "averageCost" => 6.23, "unrealizedPNL" => 1.4, "realizedPNL" => 0.0, "accountName" => "DU186928", 'currency' => 'USD'}
  end
  
  def account_summary_buying_power
    {"accountName" => "DU186928", "key" => "BuyingPower", "value" => "3996274.06", "currency" => "USD", "reqId" => "0"}
  end
  
  def account_summary_net_liquidation
    {"accountName" => "DU186928", "key" => "NetLiquidation", "value" => "0.00", "currency" => "USD", "reqId" => "0"}
  end
  
  def account_summary_total_cash_balance
    {"accountName" => "DU186928", "key" => "TotalCashBalance", "value" => "997756.47", "currency" => "USD", "reqId" => "0"}
  end
  
  def order_status_hash(basket_id, order_id, type)
    { 
      :submitted => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"100", "remaining"=>"900", "avgFillPrice"=>"6.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"},
      :submitted2 => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"130", "remaining"=>"870", "avgFillPrice"=>"7.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"},
      :submitted3 => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Submitted", "filled"=>"170", "remaining"=>"0", "avgFillPrice"=>"5.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"},
      :filled => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Filled", "filled"=>"1000", "remaining"=>"0", "avgFillPrice"=>"6.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"},
      :cancelled => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Cancelled", "filled"=>"1000", "remaining"=>"1", "avgFillPrice"=>"6.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"},
      :other => {"basketId"=>"#{basket_id}:#{order_id.to_s}", "exchange"=>"SEHK", "symbol"=>"AAPL", "orderId"=>"10000192", "status"=>"Other", "filled"=>"1000", "remaining"=>"0", "avgFillPrice"=>"6.08", "side" => type.to_s, "permId"=>"650979143", "parentId"=>"0", "lastFillPrice"=>"6.08", "clientId"=>"13", "whyHeld"=>"null"}  
    }
  end
end

RSpec.configure do |config|
  config.include TestCaseDataHelpers
end