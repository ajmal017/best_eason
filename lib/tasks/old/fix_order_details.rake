namespace :caishuo do

  desc "fix order details"
  task :fix_order_details => :environment do
    puts "====begin===="
    OrderDetail.find_each{|x| x.save }

    PositionArchive.order(:id).find_each do |p|
      puts p.id
      close_price = HistoricalQuote.where(base_stock_id: p.base_stock_id).where("date <= ?", p.archive_date).order(date: :desc).first.try(:last)
      p.update(close_price: close_price) if close_price
    end

    Position.find_each do |p| 
      puts p.id
      p.save
    end
    
    error_ids = PositionArchive.where("shares > 0 and close_price is null").map(&:base_stock_id).uniq
    if error_ids.present?
      puts "疑似非法归档数据为======================="
      puts error_ids
    end

    InvestmentCache.perform

    puts "END"
  end
end
