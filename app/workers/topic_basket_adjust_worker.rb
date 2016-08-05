class TopicBasketAdjustWorker
  @queue = :topic_basket_adjust
  
  def self.perform
    Topic.visible.each do |topic|
      topic.convert_to_basket
    end
  end

end
