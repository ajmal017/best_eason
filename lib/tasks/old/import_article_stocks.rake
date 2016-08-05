namespace :caishuo do
  desc "迁移article stocks"
  task :import_article_stocks => :environment do
    Article.find_each do |article| 
      next if article.related_stocks.blank?
      
      puts article.id
      article.related_stocks.split(',').each do |stock_id|
        ArticleStock.create(article_id: article.id, stock_id: stock_id)
      end

    end
  end

  desc "更新article stocks"
  task :update_article_stocks => :environment do
    Article.find_each do |article|
      next if article.related_stocks.blank?

      puts article.id
      article.related_stocks.split(',').each do |stock_id|
        ArticleStock.find_or_create_by(article_id: article.id, stock_id: stock_id)
      end
    end
    # 清空缓存
    $redis.keys("views/stock:focus:*").each{|k| $redis.del(k) }
  end

end
