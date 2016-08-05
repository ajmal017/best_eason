namespace :caishuo do

  desc "20151009 Feed改版"
  task :reset_news_categories => :environment do
    puts "----------生成新的 FeedCategory 开始------"
    MD::FeedCategory.reset_all
    puts "----------生成新的 FeedCategory 已完成------"


    puts "----------重置BaseRecommend 开始------"
    category_names = BaseRecommend.distinct(:category).pluck(:category).to_a.compact
    puts "----------重置BaseRecommend #{category_names * ","}------"

    category_names.each do |category_name|
      BaseRecommend.where(category: category_name).update_all(category_id: MD::FeedCategory.where(name: category_name).first.try(:category_id))
      puts "----------重置BaseRecommend 进度: #{category_name}------" 
    end

    empty_categories_records = BaseRecommend.where(category_id: nil).count

    puts "----------重置BaseRecommend 结束, 无分类的推荐数目: #{empty_categories_records}------"


    puts %Q{
    # 3. 导入新闻源 (stock项目, 快)
    # RACK_ENV=production rake es:spider_news:set_default_source

    # 4. 更新Mongodb新闻的 source_id  category_id (stock项目, 快)
    # RACK_ENV=production rake es:spider_news:source_id_migration
    # RACK_ENV=production rake es:spider_news:category_id_migration

    # 5. 重建ES新闻索引 （stock项目 慢 20分钟）
    # RACK_ENV=production rake es:spider_news:reindex
    }

end
  
end