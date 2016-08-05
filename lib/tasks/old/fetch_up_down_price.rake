namespace :stocks do
  desc "compare prices"
  task :compare_prices => :environment do
    BaseStock.cn.except_neeq.except_x.order(:id).find_each do |bs|
      quote = $redis.hgetall("realtime:#{bs.id}")
      if quote["up_price"].nil? || quote["down_price"].nil?
        puts "######{bs.id} #{bs.symbol}" 
        next
      end
      unless bs.up_price == quote["up_price"].to_d && bs.down_price == quote["down_price"].to_d
        puts "#{bs.id} #{bs.symbol} #{bs.up_price} #{quote["up_price"].to_f}"
      end
    end
  end

  desc ""
  task :fetch_up_down_price => :environment do
    error_ids = []
    BaseStock.cn.except_neeq.except_x.order(:id).find_each do |bs|
      symbol = bs.symbol.split('.').reverse.map(&:downcase).join

      response = Typhoeus.get("http://qt.gtimg.cn/q=" + symbol)
      
      if response.body.blank?
        puts "抓取失败#{bs.id}"
        next
      end
      
      begin
      body = response.body.split("~")[-3..-1]
      
      puts "#{bs.id} #{body[0]} #{body[1]}"
      $redis.mapped_hmset("realtime:#{bs.id}", {up_price: body[0], down_price: body[1]})
      rescue 
        error_ids << bs.id
        next
      end
    end

    puts "#############"
    puts error_ids
  end

end
