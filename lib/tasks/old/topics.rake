namespace :topics do
  desc "初始化相关组合count"
  task :init_baskets_count => :environment do
    Topic.find_each do |t|
      t.update(baskets_count: t.related_basket_ids.count)
    end
  end

  desc "重跑topic_basket"
  task :rerun_topic_basket => :environment do
    TopicBasket.all.destroy_all
    Tagging.where(taggable_type: "Basket").delete_all
    
    Topic.all.each do |topic|
      topic.update_related_baskets
    end
  end
end