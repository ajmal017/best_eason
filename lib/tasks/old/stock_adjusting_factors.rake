namespace :stock_adjusting_fatocrs do
  desc "初始化所有关注数据price"
  task :process_old_followed_prices => :environment do
  	# 以后每次重新跑时，把ori_price赋值给price
  	ActiveRecord::Base.connection.execute("update follows set price = ori_price;")

    StockAdjustingFactor.order(ex_divi_date: :asc).each do |saf|
      saf.adjust_followed_prices
      puts saf.id
    end
    puts "Over!"
  end
end