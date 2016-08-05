module Entities
  class Broker < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "内部id"}
    expose :name, documentation: {type: String, desc: "券商名字"}
    expose :cname, documentation: {type: String, desc: "券商别名"}
    expose :mobile_bind_url, documentation: {type: String, desc: "券商绑定页url"}
    expose :market, documentation: {type: String, desc: "券商经营的股票市场"} do |data, options|
      data.market.split(",").map { |market| ::Broker::MARKET_AREA_NAMES[market.to_sym] }
    end
    expose :logo, documentation: {type: String, desc: "券商logo图片地址"} do |data, options|
      data.logo_url(:large)
    end
    expose :small_logo, documentation: {type: String, desc: "券商logo图片地址"} do |data, options|
      data.logo_url(:small)
    end
  end

  class TradingAccount < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "交易账户内部id"} do |data, options|
      data.pretty_id
    end
    expose :broker, using: "::Entities::Broker", documentation: {type: Integer, desc: "券商信息"} do |data, options|
      data.broker
    end
    expose :broker_no, documentation: {type: Integer, desc: "绑定的账号"}
    expose :password_type, documentation: {type: Integer, desc: "登录验证类型 0 不需要验证 1 只需要密码 2 密码和通讯密码"} do |data, options|
      data.broker.need_password_type
    end
    expose :status, documentation: {type: Float, desc: "账户净值"}
    expose :total_property, documentation: {type: Float, desc: "账户净值"}
    expose :today_profit, documentation: {type: Float, desc: "今日盈亏"} do |data, options|
      PositionArchive.today_profit(data)[0]
    end
    expose :status, documentation: {type: Integer, desc: "绑定状态"}
    expose :status_name, documentation: {type: String, desc: "状态名"}
    expose :updated_at, documentation: {type: String, desc: "更新时间"}
    expose :analog, documentation: {type: Grape::API::Boolean, desc: "是否为模拟炒股帐号" } do |data, options|
      data.analog?
    end
  end

  class OrderDetail < ::Entities::Base
    expose :base_stock_id, documentation: {type: Integer, desc: "股票id"}
    expose :base_stock_name, documentation: {type: Integer, desc: "股票名称"} do |data, option|
      data.stock.try(:c_name) || data.stock.try(:name)
    end
    expose :symbol, documentation: {type: String, desc: "股票代码"}
    expose :limit_price, documentation: {type: Float, desc: "委托价格"}, format_with: :to_f
    expose :est_cost, documentation: {type: Float, desc: "预期总价格"}, format_with: :to_f
    expose :real_cost, documentation: {type: Float, desc: "实际总价格"}, format_with: :to_f
    expose :est_shares, documentation: {type: Float, desc: "预期交易数量"}, format_with: :to_f
    expose :real_shares, documentation: {type: Float, desc: "实际交易数量"}, format_with: :to_f
    expose :average_cost, documentation: {type: Float, desc: "平均成交价格"} do |data, options|
      data.avg_price.to_f
    end
    expose :commission, documentation: {type: Float, desc: "佣金"}, format_with: :to_f
    expose :currency, documentation: {type: String, desc: "货币"}
    expose :trade_time, documentation: {type: String, desc: "交易时间"}
    expose :status, documentation: {type: String, desc: "状态 ready: 交易中, submitted: 交易中, filled:  成交, partial_filled: 部分完成, cancelled: 取消, expired: 失效, error: 出错, inactive: 无效, rejected: 无法下单, api_cancelled: 无法下单"}
  end

  class Order < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "订单id"}
    expose :product_type, documentation: {type: String, desc: "订单所属类型(stock: 个股, basket: 组合)"}
    expose :status, documentation: {type: String, desc: "状态, unconfirmed: '未确认', confirmed: '执行中', partial_completed: '部分完成', completed: '交易完成', cancelled: '交易取消', expired: '失效', error: '出错', cancelling: '取消中' "}
    expose :created_at, documentation: {type: String, desc: "创建时间"}
    expose :updated_at, documentation: {type: String, desc: "更新时间"}
    expose :expiry, documentation: {type: String, desc: "到期时间"}
    expose :type, documentation: {type: String, desc: "买卖类型 OrderSell OrderBuy"}
    expose :market, documentation: {type: String, desc: "市场"}
    expose :sn, documentation: {type: String, desc: "sn"}
    expose :exchange, documentation: {type: String, desc: "交易市场"}
    expose :commission, documentation: {type: Float, desc: "佣金"}, format_with: :to_f
    expose :est_cost, documentation: {type: Float, desc: "预期总价格"}, format_with: :to_f
    expose :real_cost, documentation: {type: Float, desc: "实际总价格"}, format_with: :to_f
    expose :order_details, using: "::Entities::OrderDetail", documentation: {type: Array, desc: "订单对应信息"}
  end
end
