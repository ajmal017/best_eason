class P2pAd
  include RedisRecord

  ALLOW_COUNT = 5

  has_attributes :title, :url, presence: :title

  def self.result_for_app
    all_without_nil.map do |ad|
      {title: ad.title, url: ad.url}
    end
  end

end
