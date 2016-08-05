class StockRealtimeConsumer
  include Sneakers::Worker
  include Trading::AckHelper

  from_queue 'com.caishuo.stocks_realtime', :threads => 2, :prefetch => 1, :exchange_arguments => {
    "alternate-exchange" => "caishuox.unroutable"
  }

  # msg:
  # {"base_stock_id":"9828","symbol":"600997.SH","last":"6.0","change_from_previous_close":"0.16",
  #  "percent_change_from_previous_close":"2.74","volume":"24204583",
  #  "bid_prices":"5.99,5.98,5.97,5.96,5.95","bid_sizes":"71000,19800,40600,36700,41500",
  #  "offer_prices":"6.0,6.01,6.02,6.03,6.04","offer_sizes":"119804,62300,98600,67200,78500",
  #  "low":"5.82","high":"6.02","low52_weeks":"4.66","high52_weeks":"10.756",
  #  "trade_time":"2015-10-16 14:09:35","market":"cn","trade_at":"1444975775000",
  #  "top_price":"6.42","bottom_price":"5.26","listed_state":"1","listed_first_day":"0",
  #  "rt_logs":["600997.SH,6.0,16000,2015-10-16 14:09:35","600997.SH,6.0,2500,2015-10-16 14:09:25","600997.SH,5.99,31100,2015-10-16 14:09:10","600997.SH,5.99,2000,2015-10-16 14:09:00","600997.SH,6.0,2300,2015-10-16 14:08:50","600997.SH,5.99,1600,2015-10-16 14:08:40","600997.SH,5.99,1600,2015-10-16 14:08:35","600997.SH,5.99,6000,2015-10-16 14:08:20","600997.SH,5.98,39000,2015-10-16 14:08:10","600997.SH,5.99,8200,2015-10-16 14:07:54"],"push_at":1444976613075}

  def work(msg)
    stocks = JSON.parse(msg)

    if (stocks.first["market"] != "cn") || (stocks.first["push_at"].to_i/1000 >= (Time.now.to_i - 30))
      msgs = []
      stocks.each do |attrs|
        attrs.symbolize_keys!
        attrs.merge!(base_stock_id: attrs[:base_stock_id].to_i, percent_change_from_previous_close: attrs[:percent_change_from_previous_close].to_f)
        msgs << {update_one: {filter: {base_stock_id: attrs[:base_stock_id]}, update: {"$set" => attrs }, upsert: true } }
        # MD::RS::Stock.where(base_stock_id: attrs[:base_stock_id]).find_and_modify(attrs, {upsert: true})
      end
      MD::RS::Stock.collection.bulk_write msgs
    end
    ack!
  rescue => e
    logger.error e.inspect
    logger.error e.exception
    to_dead_letter!
  end

end