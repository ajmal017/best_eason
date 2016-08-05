class Panel
  include RedisRecord

  has_attributes :title, :type, :obj_id, presence: :title

  TYPE = [["用户", "1"], ["股票", "2"], ["组合", "3"]]

  def type_zh
    TYPE.find{|t| t.last == type}.first rescue nil
  end

  def self.result_for_app
    all_without_nil.map do |panel|
      r = {title: panel.title, type: panel.type}
      case panel.type.to_i
      when 1
        user = User.find_by(id: panel.obj_id)
        if user.present?
          r[:user_id] = user.id
          r[:total_profit] = user.best_basket_ret.to_f rescue nil
          r[:username] = user.username
          r[:avatar] = user.avatar.url
        end
      when 2
        stock = BaseStock.find_by(id: panel.obj_id)
        if stock.present?
          r[:stock_id] = stock.id
          r[:stock_name] = stock.c_name || stock.name
          r[:realtime_price] = stock.realtime_price
          r[:market] = stock.market_area
          r[:change_percent] = stock.change_percent
          r[:symbol] = stock.symbol
        end
      when 3
        basket = Basket.find_by(id: panel.obj_id)
        if basket.present?
          r[:basket_id] = basket.id
          r[:basket_title] = basket.title
          r[:contest] = basket.contest
          r[:one_month_return] = basket.one_month_return.try(:to_f)
        end
      end
      r
    end
  end

end
