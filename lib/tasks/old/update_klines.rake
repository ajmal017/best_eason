namespace :caishuo do

  # 更新Klines
  desc "update klines"
  task :update_klines => :environment do
    BaseStock.limit(10).find_each do |bs|
      puts bs.id
      Kline.new(base_stock_id: bs.id, category: 0).import!
      Kline.new(base_stock_id: bs.id, category: 1).import!

    end
    
    puts "=======end======="
  end
end
