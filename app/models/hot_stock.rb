class HotStock
  include RedisRecord

  has_attributes :title, :stock_ids, presence: :title

  def self.result_for_app
    all_without_nil.map do |hs|
      r = {title: hs.title}

      stocks = BaseStock.where(id: hs.stock_ids.try(:split, ","))
      r[:stocks] = stocks.map do |s|
        {
          id: s.id,
          name: s.c_name||s.name,
          market: s.market_area,
          realtime_price: s.realtime_price,
          change_percent: s.change_percent
        }
      end
      r
    end
  end

end
