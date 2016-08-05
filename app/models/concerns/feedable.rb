module Feedable
  extend ActiveSupport::Concern
  included do
    attr_accessor :feed_type
    after_commit :add_feed, on: [:create], if: :feed_type
  end

  # 设置需要feed
  def need_feed(source_feed_type)
    self.feed_type = source_feed_type
  end

  def add_feed(source_feed_type=nil)
    MD::Feed.add(source_feed_type||feed_type, user.mongo, self)
  end

  
end
