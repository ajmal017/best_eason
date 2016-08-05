class TopicBasketWorker
  @queue = :topic
  
  def self.perform
    Topic.all.each do |topic|
      begin
        topic.update_float_pool
        topic.update_related_baskets
        topic.reset_articles
        topic.update_hot_score
      rescue
        puts topic.id
      end
    end
    
  end

end
