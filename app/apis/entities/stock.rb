module Entities
  class StockReminder < ::Entities::Base
    expose :stock_id, documentation: {type: Integer, desc: "股票id"}
    expose :stock_name, documentation: {type: String, desc: "股票名称"} do |data, options|
      data.stock.try(:c_name)
    end
    expose :reminder_type, as: :type, documentation: {type: String, desc: "提醒触发类型"}
    expose :reminder_value, as: :value, documentation: {type: Float, desc: "提醒触发的值"}, format_with: :to_f
  end

  class RealTimeStock < ::Entities::Base
    # 实时数据
    # =======================
    expose :id, documentation: {type: Integer, desc: "内部id"}
    expose :integrate_status, as: :trading_status, documentation: {type: String, desc: "交易状态"}
    expose :trading_time, documentation: {type: String, desc: "交易时间"} do |data, options|
      "#{DateTime.parse(data.trade_time_str).strftime('%H:%M:%S') rescue ''} (#{data.market_time_desc})"
    end
    expose :realtime_price, documentation: {type: Float, desc: "当前价格"} do |data, options|
      format_float_with_nil(data, :realtime_price)
    end
    expose :previous_close, documentation: {type: Float, desc: "昨日收盘价"} do |data, options|
      format_float_with_nil(data, :previous_close)
    end
    expose :change_percent, documentation: {type: Float, desc: "涨跌幅"} do |data, options|
      format_float_with_nil(data, :change_percent)
    end
    expose :change_from_previous_close, as: :change_price, documentation: {type: Float, desc: "涨跌价格"} do |data, options|
      format_float_with_nil(data, :change_from_previous_close)
    end
    expose :bids, documentation: {type: Array, desc: "买5"}, if: {type: :stock}
    expose :offers, documentation: {type: Array, desc: "卖5"}, if: {type: :stock}
    expose :rt_logs, documentation: {type: Array, desc: "逐笔交易数据"}, if: {type: :stock}
    with_options(format_with: :to_f) do
      expose :amplitude, documentation: {type: Float, desc: "振幅"}, if: {type: :stock} do |data, options|
        data.amplitude.to_f rescue nil
      end
      expose :non_restricted_market_capitalization, documentation: {type: Float, desc: "流通市值"}, if: {type: :stock} do |data, options|
        data.non_restricted_market_capitalization.to_f rescue nil
      end
      expose :net_asset_rate, documentation: {type: Float, desc: "市净率"}, if: {type: :stock} do |data, options|
        data.net_asset_rate.to_f rescue nil
      end
      expose :market_capitalization, documentation: {type: Float, desc: "总市值"}, if: {type: :stock} do |data, options|
        data.market_capitalization.to_f rescue nil
      end
      expose :pe_ratio, documentation: {type: Float, desc: "市盈率"}, if: {type: :stock} do |data, options|
        data.pe_ratio.to_f rescue nil
      end
      expose :lastest_volume, as: :volume, documentation: {type: Float, desc: "成交量"}, if: {type: :stock}
      expose :high, documentation: {type: Float, desc: "今高"}, if: {type: :stock}
      expose :low, documentation: {type: Float, desc: "低"}, if: {type: :stock}
      expose :high52_weeks, documentation: {type: Float, desc: "52周高"}, if: {type: :stock}
      expose :low52_weeks, documentation: {type: Float, desc: "52周低"}, if: {type: :stock}
      expose :turnover_rate, documentation: {type: Float, desc: "换手率"}, if: {type: :stock}
      expose :eps, documentation: {type: Float, desc: "eps"}, if: {type: :stock}
      expose :dividend, documentation: {type: Float, desc: "股息"}, if: {type: :stock} do |data, options|
        data.dividend.to_f rescue nil
      end

      # 与 open_uri 命名冲突
      expose :open, documentation: {type: Float, desc: "今开"}, if: {type: :stock} do |data, options|
        data.open.to_f
      end
      expose :up_price, documentation: {type: Float, desc: "涨停价"} do |data, options|
        data.up_price.to_f rescue 0
      end
      expose :down_price, documentation: {type: Float, desc: "跌停价"} do |data, options|
        data.down_price.to_f rescue 0
      end
      expose :turnover, documentation: {type: Float, desc: "成交额"}, if: {type: :stock} do |data, options|
        data.turnover.to_f rescue nil
      end
      expose :volume_ratio, documentation: {type: Float, desc: "量比"}, if: {type: :stock} do |data, options|
        data.volume_ratio.to_f rescue nil
      end
      expose :bid_ratio, documentation: {type: Float, desc: "委比"}, if: {type: :stock} do |data, options|
        data.bid_ratio.to_f rescue nil
      end
    end
  end

  class Stock < ::Entities::RealTimeStock
    expose :is_index, documentation: {type: Grape::API::Boolean, desc: "是否是大盘指数"} do |data, options|
      data.is_index?
    end
    expose :name, documentation: {type: String, desc: "名称"}
    expose :symbol, documentation: {type: String, desc: "股票代码"}
    expose :chi_spelling, documentation: {type: String, desc: "首拼"}
    expose :comments_count, documentation: {type: Float, desc: "评论数量"}
    expose :com_name, documentation: {type: String, desc: "中文名称"} do |data, options|
      data.c_name || data.name
    end
    expose :followed, documentation: {type: Grape::API::Boolean, desc: "是否自选股"} do |data, options|
      data.followed_by?(options[:current_user].try(:id))
    end
    expose :screenshot, documentation: {type: String, desc: "行情图片"} do |data, options|
      data.screenshot
    end
    expose :board_lot, documentation: {type: Integer, desc: "手"} do |data, options|
      data.board_lot rescue 1
    end
    expose :exist_reminder, documentation: {type: Grape::API::Boolean, desc: "是否设置了股价提醒"} do |data, options|
      options[:current_user].present? ? data.exist_reminder?(options[:current_user]) : false
    end
    expose :position, documentation: {type: Array, desc: "我的持仓信息"}, if: {type: :stock} do |data, options|
      if options[:current_user].present? && account = ::TradingAccount.binded.by_user(options[:current_user].id)
        ::Position.stock_profits_total(data.id, options[:current_user])
      else
        []
      end
    end
    expose :market_area_name, as: :market, documentation: {type: String, desc: "交易市场"}
    expose :listed_state, documentation: {type: Integer, desc: "状态"} do |data, options|
      data.listed_state rescue 1
    end
    expose :positioned, documentation: {type: Grape::API::Boolean, desc: "是否持仓"}, if: {type: :market} do |data, options|
      options[:current_user].present? && options[:current_user].positioned?(data.id)
    end

    expose :my_friends_followed_stock, using: "::Entities::User", documentation: {type: Array, desc: "关注该股票的我的好友"}, if: {type: :stock} do |data, options|
      if options[:current_user].present?
        options[:current_user].friends.map(&:followable).select { |user| data.followed_by?(user.id) }
      else
        []
      end
    end
    expose :my_friends_positioned_stock, using: "::Entities::User", documentation: {type: Array, desc: "持有该股票的我的好友"}, if: {type: :stock} do |data, options|
      if options[:current_user].present?
        options[:current_user].friends.map(&:followable).select { |user| user.positioned?(data.id) }
      else
        []
      end
    end
    expose :currency_unit, as: :current_currency_unit, documentation: {type: String, desc: "币种"}, if: {type: :stock}
    expose :market_capitalization, documentation: {type: Float, desc: "market_capitalization"}, if: {type: :stock} do |data, options|
      format_method_with_nil(data, :market_capitalization, :to_f)
    end
    expose :average_daily_volume, documentation: {type: Float, desc: "average_daily_volume"}, if: {type: :stock} do |data, options|
      format_float_with_nil(data, :adj_average_daily_volume)
    end
    expose :pe_ratio, documentation: {type: Float, desc: "pe_ratio"}, if: {type: :stock} do |data, options|
      format_float_with_nil(data, :pe_ratio)
    end
    expose :flow_charts, documentation: {type: Array, desc: "主力资金饼图数据"}, if: {type: :stock} do |data, options|
      result = RestClient.api.stock.trading_flow.pie(data.id)
      result.in_groups_of(2).map(&:sum)
    end

    expose :funds_flow, documentation: {type: Hash, desc: "五日资金流向"}, if: {type: :stock} do |data, options|
      result = RestClient.api.stock.trading_flow.funding(data.id, 5) || {}
      result.map{|k,v| {date: k, value: v} }
    end

  end

  class IndexStock < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "内部id"}
    expose :name, documentation: {type: String, desc: "名称"}
    expose :symbol, documentation: {type: String, desc: "股票代码"}
    expose :followed, documentation: {type: Grape::API::Boolean, desc: "是否自选股"} do |data, options|
      data.followed_by?(options[:current_user].try(:id))
    end
    expose :com_name, documentation: {type: String, desc: "中文名称"} do |data, options|
      data.c_name || data.name
    end
    expose :score, documentation: {type: Float, desc: "财说score"} do |data, options|
      data.stock_screener.score.to_f rescue nil
    end
    expose :realtime_price, documentation: {type: Float, desc: "当前价格"} do |data, options|
      format_float_with_nil(data, :realtime_price)
    end
    expose :change_percent, documentation: {type: Float, desc: "涨跌幅"} do |data, options|
      format_float_with_nil(data, :change_percent)
    end
  end

  class StockDetail < ::Entities::Base
    expose :com_intro, documentation: {type: String, desc: "简介"}
    expose :score, documentation: {type: Float, desc: "财说score"} do |data, options|
      data.stock_screener.score.to_f rescue nil
    end
    expose :score_values, documentation: {type: Array, desc: "评分"} do |data, options|
      data.stock_screener.score_values rescue []
    end

    expose :news, documentation: {type: Array, desc: "新闻"}

    expose :announcements, documentation: {type: Array, desc: "公告"}

    expose :related_stocks, documentation: {type: Array, desc: "相关股"} do |data, options|
      data.stock_screener.competitors.where("id != ?", data.id).limit(4).map do |stock|
        {
          id: stock.id,
          name: stock.c_name||stock.name,
          realtime_price: stock.realtime_price.to_f,
          score: stock.stock_screener.score.to_f,
          change_percent: stock.change_percent.to_f
        }
      end rescue []
    end

    expose :asc_stocks, using: "::Entities::IndexStock", documentation: {type: Hash, desc: "领涨榜股票"}, if: {type: :index} do |data, options|
      data.top_stocks_by_exchange("asc", 15)
    end

    expose :desc_stocks, using: "::Entities::IndexStock", documentation: {type: Hash, desc: "领跌榜股票"}, if: {type: :index} do |data, options|
      data.top_stocks_by_exchange("desc", 15)
    end
  end
end
