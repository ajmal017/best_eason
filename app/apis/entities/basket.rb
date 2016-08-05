module Entities
  class BasketStock < ::Entities::Base

    expose :id, documentation: {type: String, desc: "ID"} do |data, options|
      data.stock.try(:id)
    end
    expose :name, documentation: {type: String, desc: "名称"} do |data, options|
      data.stock.try(:name)
    end
    expose :symbol, documentation: {type: String, desc: "股票代码"} do |data, options|
      data.stock.try(:symbol)
    end
    expose :com_name, documentation: {type: String, desc: "中文名称"} do |data, options|
      data.stock.try(:c_name) || data.stock.try(:name)
    end
    expose :listed_state, documentation: {type: Integer, desc: "股票状态"} do |data, options|
      data.stock.try(:listed_state) || 1
    end

    expose :action, documentation: {type: Integer, desc: "操作"} do |data, options|
      bals = options[:bals]
      if bals.present?
        bals.find{|log| log.stock_id == data.stock_id}.try(:action) || 0
      else
        0
      end
    end

    expose :realtime_price, documentation: {type: Float, desc: "当前价格"} do |data, options|
      format_float_with_nil(data.stock, :realtime_price)
    end
    expose :change_percent, documentation: {type: Float, desc: "一天回报"} do |data, options|
      format_float_with_nil(data.stock, :change_percent)
    end
    expose :weight, documentation: {type: Float, desc: "比重"}, format_with: :to_f

  end

  class BasketAdjustLog < ::Entities::Base
    expose :stock_id, documentation: {type: Integer, desc: "股票ID"}
    expose :stock_symbol, documentation: {type: Integer, desc: "股票代码"} do |data, options|
      data.stock.symbol rescue nil
    end
    expose :stock_name, documentation: {type: String, desc: "名称"} do |data, options|
      data.stock.try(:com_name) || "现金"
    end
    expose :action_desc, documentation: {type: String, desc: "行为描述"}
    expose :action, documentation: {type: Integer, desc: "行为 {1 => '新增', 2 => '删除', 3 => '加仓', 4 => '减仓'} "}

    with_options(format_with: :to_f) do
      expose :weight_from, documentation: {type: Float, desc: "调整前比例"}
      expose :weight_to, documentation: {type: Float, desc: "调整后比例"}
      expose :stock_price, documentation: {type: Float, desc: "调整时价格"}
    end
  end

  class BasketAdjustment < ::Entities::Base
    expose :created_at, documentation: {type: String, desc: "调仓时间"}
    expose :state, documentation: {type: Integer, desc: "调仓时状态 0 交易时间段正常调仓 1 非交易时段调仓、待成交 2 开市矫正盘后-盘前的调仓 4 系统开始检测不合法时回退并取消调仓 5 隐藏"}
    expose :basket_adjust_logs_desc, as: :basket_adjust_logs, using: "::Entities::BasketAdjustLog", documentation: {type: Array, desc: "调仓日志"}
  end

  class Tag < ::Entities::Base
    expose :id, documentation: {type: Integer, desc: "ID"}
    expose :name, documentation: {type: String, desc: "名称"}
  end

  class BasketSearch < ::Entities::Base
    expose :keyword, documentation: {type: String, desc: "搜索关键字"}
    expose :tag, documentation: {type: String, desc: "标签 ID", default: "all"}
    expose :filter, documentation: {type: String, values: ["contest"], desc: "过滤条件"}
    expose :market, documentation: {type: String, values: ::Basket::MARKET.keys, desc: "按照市场搜索", default: "all"}
    expose :order, documentation: {type: String, values: ::Basket::SEARCH_ORDER_FIELD_MAP.keys, desc: "排序依据", default: "1m_return"}
  end

  class Basket < ::Entities::Base

    expose :id, documentation: {type: Integer, desc: "ID"}
    expose :title, documentation: {type: String, desc: "标题"}

    with_options(format_with: :to_f) do
      expose :realtime_total_return, as: :return_from_start_on, documentation: {type: Float, desc: "总收益"}
      expose :one_day_return, documentation: {type: Float, desc: "一日收益"}
      expose :one_month_return, documentation: {type: Float, desc: "一月收益"}
      expose :three_month_return, documentation: {type: Float, desc: "三月收益"}
      expose :one_year_return, documentation: {type: Float, desc: "一年收益"}
      expose :change_percent, documentation: {type: Float, desc: "当前涨跌"}
    end

    expose :contest, documentation: {type: Integer, desc: "大赛(3为实盘大赛)"}
    expose :shipan_data, documentation: {type: Hash, desc: "实盘大赛数据"} do |data, options|
      if data.shipan?

        contest = Contest.find(3)
        basket_rank = contest.basket_rank_of(data.author_id)
        account = data.pt_account

        {
          change_percent: data.shipan_ret_percent,
          total_percent: basket_rank.realtime_total_ret,
          victory: basket_rank.win_rate,
          total_property: account.try(:total_property),
          adjust_count: basket_rank.adjust_count,
          position_percent: basket_rank.position_percent,
          now_rank: basket_rank.now_rank,
          rank_change: basket_rank.rank_change,
          status: basket_rank.status_desc
        }

      else
        nil
      end
    end

    expose :realtime_index, documentation: {type: Integer, desc: "组合指数"} do |data, options|
      data.realtime_index.present? ? data.realtime_index.to_i : 0
    end
    expose :author, using: "::Entities::UserForBasket", documentation: {type: "::Entities::UserForBasket", desc: "创建用户"}
    expose :market, documentation: {type: String, desc: "市场"} do |data, options|
      ::BaseStock::MARKET_AREA_NAMES[data.market.try(:to_sym)]
    end
    expose :follows_count, documentation: {type: Integer, desc: "关注人数"}
    expose :likes_count, documentation: {type: Integer, desc: "点赞人数"}
    expose :modified_at, documentation: {type: String, desc: "更新时间"}
    expose :created_at, documentation: {type: String, desc: "创建时间"}
    expose :last_ajustment_time, documentation: {type: String, desc: "最后调仓时间"}
    expose :ajustment_info_zh, documentation: {type: String, desc: "调仓信息描述"}
    expose :ajustment_info_action, documentation: {type: Integer, desc: "调仓action"}
    expose :full_tags, as: :tags, using: "::Entities::Tag", documentation: {type: Array, desc: "所属标签"}

    expose :positioned, documentation: {type: Grape::API::Boolean, desc: "是否持仓"}, if: {type: :trade} do |data, options|
      data.is_position_by?(options[:current_user].try(:id))
    end

    expose :followed, documentation: {type: Grape::API::Boolean, desc: "是否关注"} do |data, options|
      data.followed_by_user?(options[:current_user].try(:id))
    end

    #expose :followed_price, documentation: {type: Grape::API::Boolean, desc: "关注时价格"} do |data, options|
      #if data.followed_by_user?(options[:current_user].try(:id))
      #end
    #end

    expose :comments_count, documentation: {type: Integer, desc: "评论数"}
    with_options(if: {type: :detail}) do
      expose :description, documentation: {type: String, desc: "描述内容"}
      expose :position_scale, documentation: {type: Array, desc: "仓位比例"}
      expose :img, documentation: {type: String, desc: "图片"} do |data, options|
        data.img.url
      end
      # 已废弃，兼容老版本保留
      expose :comments, documentation: {type: Array, desc: "组合评论"} do |data, options|
        []
      end
    end

  end
end
