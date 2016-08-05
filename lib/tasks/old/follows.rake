namespace :follows do
  desc "初始化老stock follow的price"
  task :init_old_stock_follows => :environment do
    no_price_ids = []
    Follow::Stock.find_each do |follow|
      next if follow.price.present?

      stock = follow.followable
      date = ClosedDay.get_work_day(follow.created_at.to_date, stock.market_area)
      last_close = stock.send(:historical_quote_class).by_base_stock_id(stock.id).by_date(date).first.try(:last_close)
      if last_close.blank?
        no_price_ids << follow.id
        next
      end
      follow.update(price: last_close)
    end
    puts "没有当天价格数据的follow ids：#{no_price_ids.join(", ")}"
  end

  task :init_old_stock_follows => :environment do
    no_price_ids = []
    Follow::Stock.where("price is null").find_each do |follow|
      next if follow.price.present?
      stock = follow.followable
      follow.update(price: stock.realtime_price) if follow.created_at.to_date == Date.today
    end
    puts "没有当天价格数据的follow ids：#{no_price_ids.join(", ")}"
  end

  desc "关注从多态迁移到单表继承"
  task :convert_polymorphic_to_extend => :environment do
    ActiveRecord::Base.connection.execute("update follows set type = CONCAT('Follow::',followable_type) where followable_id is not null")
    ActiveRecord::Base.connection.execute("update follows set followable_id = followed_user_id, followable_type = 'User', type = 'Follow::User' where followable_id is null")
    ActiveRecord::Base.connection.execute("update follows set type = 'Follow::Stock' where type = 'Follow::BaseStock' ")
  end
end