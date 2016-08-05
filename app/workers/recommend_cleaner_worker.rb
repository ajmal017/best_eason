class RecommendCleanerWorker
  @queue = :recommend_cleaner_worker
  
  def self.perform
    BaseRecommend.un_published.where("created_at NOT BETWEEN ? AND ?", Time.now-5.day, Time.now).destroy_all
  end
end
