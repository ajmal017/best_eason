class SymbolTopicMaper

  def self.store_all
    delete_all

    mappings = TopicStock.where(fixed: true).joins(:base_stock, :topic)
              .where("topics.visible = true")
              .select("base_stocks.symbol, topic_id, topics.title")
              .pluck(:symbol, :topic_id, :title).group_by{|x| x[0] }
    mappings.each do |symbol, datas|
      topics = datas.first(10).map{|x| [x[1], x[2]]}.to_h
      SymbolTopicMaper.create(symbol, topics)
    end

    to_file
  end

  def self.create(symbol, topics)
    $redis.mapped_hmset redis_key(symbol), topics
  end

  def self.find(symbol)
    datas = $redis.hgetall( redis_key(symbol) ) || {}
    datas.map do |topic_id, title|
      { name: title, url: zxg_topic_url(topic_id) }
    end
  end

  def self.to_file
    dir = "public/caches/market/zxg/"
    areas = %w(cn us hk)
    areas.each do |area|
      CSV.open("#{dir}#{area}.csv", "wb") do |csv|
        "Stock::#{area.capitalize}".constantize.select(:id, :symbol, :exchange).find_each do |stock|
          data = SymbolTopicMaper.find(stock.symbol)
          csv << [Caishuo::Utils::SymbolConverter.cs_to_zxg(stock.symbol, stock.market_area), data.to_json] if data.present?
        end
      end
    end
  end

  def self.delete_all
    keys = $redis.keys(redis_key("*"))
    $redis.pipelined do
      keys.map{|key| $redis.del(key) }
    end
  end

  private

  def self.redis_key(symbol)
    "cs:symbol_topics:#{symbol.downcase}"
  end

  def self.zxg_topic_url(topic_id)
    "#{Setting.http_host}/market/zxg/topics/#{topic_id}.html"
  end
end