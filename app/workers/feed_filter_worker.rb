class FeedFilterWorker
  @queue = :feed_filter

  def self.perform
    filter_types = %w(filter_industry filter_concept filter_ggzjlx)
    filter_types.map{|filter_type| MD::FeedHub.add_filter(filter_type)}
  end
end