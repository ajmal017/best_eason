class BasketRankCache < Redis::SortedSet

  # 第二轮大赛
  REDIS_KEY = 'cache:basket_rank_2'

  def initialize
    super(REDIS_KEY)
  end

  def add(*data)
    redis.zadd(data)
  end

  # mock=true 测试数据，随机生成数
  def self.load_data(mock=false)
    new.del
    data = Basket.normal.finished.contest.select(:id, :state, :market, :type, :start_on, :original_id, :contest).inject({}) do |result, basket|
      result[basket.id] = get_score(basket, mock)
      result
    end
    new.add_all(data)
    # clean_cache
  end

  # mock=true 测试数据，随机生成数
  def self.get_score(basket, mock=false)
    mock ? (rand(600) - 500)/10.0 : basket.rank_score(2)
  end

  # 排行
  # per_page: 每页条数
  # page: 第几页
  # Demo:
  # BasketRankCache.top(100) // top 1-100
  # BasketRankCache.top(10, 1) // top 11-20
  def self.top(per_page=50, page=1)
    Hash[new.revrange(per_page*(page-1), per_page*page-1, with_scores: true)]
  end

  def self.score(basket_id)
    new.score(basket_id.to_s)
  end

  # 查找名次
  def self.clean_cache
    new.redis.del("views/cs:dasai:rank", "views/cs:dasai:recommend")
  end

  def self.cache_exists?
    new.redis.exists("views/cs:dasai:rank")
  end

  def self.all_members
    new.members.reverse
  end


  def self.real_count
    new.length
  end

  def self.members_count
    init_count = $redis.get("virtual_contest_participants_count") || 0
    Basket.normal.finished.contest.count + init_count.to_i
  end

end
