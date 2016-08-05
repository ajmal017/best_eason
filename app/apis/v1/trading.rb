module V1
  class Trading < Grape::API
    resource :trading, desc: "交易相关" do

      before do
        authenticate!
      end

      add_desc "券商列表"
      get :brokers do
        present Broker.published.displayed.asc_position, with: ::Entities::Broker
      end

      add_desc "账户总值"
      get :total_accounts_amount do
        present current_user.total_accounts_amount
      end

      add_desc "查看用户账号,0: 正在审核,1: 绑定成功,2: 审核通过,3: 审核未通过"
      params do
        optional :type, type: String, desc: "券商帐号类型 all:所有 analog:模拟帐号 默认:普通帐号", values: %w[ all analog ]
      end
      get :accounts do
        trading_accounts = TradingAccount.by_user(current_user.id).includes(:broker)
        trading_accounts =
          case params[:type]
          when "all"
            trading_accounts.published(true)
          when "analog"
            trading_accounts.sim
          else
            trading_accounts.published(false)
          end
        trading_accounts = trading_accounts.sort_by_app
        present trading_accounts, with: ::Entities::TradingAccount
      end

      add_desc "查看用户某个券商下的已绑定账号"
      get "/brokers/:broker_id/accounts" do
        trading_accounts = TradingAccount.where(broker_id: params[:broker_id]).binded.by_user(current_user.id)
        present trading_accounts, with: ::Entities::TradingAccount
      end

      add_desc "绑定券商账号"
      params do
        requires :broker_no, type: String, desc: "用户证券账号"
        optional :password, type: String, desc: "密码"
        optional :safety_info, desc: "通讯密码", type: String
      end
      post "/brokers/:broker_id/accounts" do
        broker = Broker.find(params[:broker_id])
        trading_account = ::TradingAccount.bind(current_user, broker, {broker_no: params[:broker_no], password: params[:password], safety_info: params[:safety_info]})
        if trading_account.persisted? && trading_account.errors.empty?
          present trading_account, with: ::Entities::TradingAccount
        else
          raise APIErrors::VeriftyFail, "#{trading_account.errors[:broker_no].try(:first)}"
        end
      end

      add_desc "模拟账户开户"
      params do
        requires :market, type: String, desc: "模拟账户类型", values: %w[ cn hk us ], default: "cn"
      end
      post "/open_analog_account" do
        trading_account = TradingAccountSim.open(current_user.id, params[:market])
        raise APIErrors::VeriftyFail, trading_account.errors.values.flatten.join(", ") if trading_account.errors.present?
        present trading_account, with: ::Entities::TradingAccount
      end

      #add_desc "获取模拟账户"
      #params do
        #requires :market, type: String, desc: "模拟账户类型", values: %w[ cn uk us ], default: "cn"
      #end
      #get "/analog_account" do
        #trading_account = TradingAccount.open(current_user.id, params[:market].to_i)
        #present trading_account, with: ::Entities::TradingAccount
      #end

      add_desc "解绑券商账号"
      delete "/accounts/:trading_account_id" do
        if ::TradingAccount.unbind(current_user, params[:trading_account_id])
          []
        else
          raise APIErrors::VeriftyFail, "解绑失败"
        end
      end

      add_desc "券商账号详情"
      get "/accounts/:trading_account_id" do
        if trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])

          # 货币单位
          current_cash_unit = trading_account.cash_unit
          # 证券市值
          market_value = trading_account.market_value
          # 账户总金额
          total_property = trading_account.total_property
          # 持仓比例
          position_percent = market_value.zero? ? 0 : market_value.fdiv(total_property) * 100
          # 今日盈亏 盈亏百分比
          today_profit, today_profit_percent = PositionArchive.today_profit(trading_account)
          # 累计盈亏 盈亏百分比
          total_profit, total_profit_percent = Position.total_profit_and_loss(trading_account)
          # 主板 创业板分布
          sector_market_value = [] # Position.sector_market_value(trading_account)
          # 行业分布
          invest_sector_rates = [] # Investment.sector_ratio(trading_account)
          # 胜率
          win_rate = [] # Investment.winning_ratio(trading_account)
          # 换手率
          # turnover_rate = {} #Position.turnover_rate(trading_account)
          # 现金
          cash_unit = trading_account.cash_unit
          total_cash = trading_account.usable_cash
          #是否可以显示风险评估
          risk_analysis_usable = trading_account.risk_analysis_usable
          share_url = trading_account.try(:snapshot_url)


          response = {current_cash_unit: current_cash_unit, market_value: market_value, total_property: total_property,
            today_profit: today_profit, today_profit_percent: today_profit_percent, position_percent: position_percent,
            invest_sector_rates: invest_sector_rates, part_market_value: sector_market_value, win_rate: win_rate,
            total_cash: {cash_unit: cash_unit, total_cash: total_cash}, total_profit: total_profit,
            total_profit_percent: total_profit_percent, risk_analysis_usable: risk_analysis_usable,
            share_url: share_url
            }
          present response
        else
          {}
        end
      end

      add_desc "持仓盈亏"
      params do
        optional :trading_account_id, type: String, desc: "交易账户id"
        optional :type, type: String, desc: "数据类型", values: ["stock", "basket"]
      end
      get :positions do
        # 股票
        stocks =
          if params[:trading_account_id].present?
            trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
            trading_account.try(:refresh_cash)
            trading_account.present? ? Position.buyed_stocks_infos(current_user.id, trading_account) : {}
          else
            TradingAccount.binded.by_user(current_user.id).map { |account| Position.buyed_stocks_infos(current_user.id, account).map { |item| item.merge( {broker: account.broker.cname + "|" + account.broker_no}) } }.flatten
          end if [nil, "stock"].include? params[:type]

        # 组合
        baskets =
          if params[:trading_account_id].present?
            trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
            trading_account.present? ? Position.buyed_baskets_infos(current_user.id, trading_account) : {}
          else
            TradingAccount.binded.by_user(current_user.id).map { |account| Position.buyed_baskets_infos(current_user.id, account) }.flatten
          end if [nil, "basket"].include? params[:type]

        result = {}
        result[:stocks] = stocks if stocks.present?
        result[:baskets] = baskets if baskets.present?

        present result
      end

      add_desc "收益表现图"
      params do
        optional :date, type: String, desc: "开始日期，例如：2014-10-10"
        optional :end_date, type: String, desc: "结束日期，例如：2014-10-10"
        optional :count, type: Integer, desc: "返回对应天数的数据"
        at_least_one_of :date, :end_date
      end
      get "/accounts/:trading_account_id/charts/profit" do
        trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id].to_s)
        raise APIErrors::VeriftyFail, "券商帐号不存在" unless trading_account

        begin_date = Date.parse(params[:date]) rescue nil
        end_date = Date.parse(params[:end_date]) rescue nil

        datas = UserProfit.datas_by(trading_account, begin_date || '2014-10-10', end_date)

        datas = date_result_limit(datas, params[:date], params[:end_date], params[:count])

        response = {unit: trading_account.cash_unit, datas: datas}
        present response
      end

      add_desc "净值表现图"
      params do
        optional :date, type: String, desc: "开始日期，例如：2014-10-10"
        optional :end_date, type: String, desc: "结束日期，例如：2014-10-10"
        optional :count, type: Integer, desc: "返回对应天数的数据"
        at_least_one_of :date, :end_date
      end
      get "/accounts/:trading_account_id/charts/networth" do
        trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id].to_s)
        raise APIErrors::VeriftyFail, "券商帐号不存在" unless trading_account

        begin_date = Date.parse(params[:date]) rescue nil
        end_date = Date.parse(params[:end_date]) rescue nil

        datas = UserDayProperty.datas_by(trading_account, begin_date, end_date)
        datas = date_result_limit(datas, params[:date], params[:end_date], params[:count])

        response = {unit: trading_account.cash_unit, datas: datas}
        present response
      end

      add_desc "比一比社交数据"
      get "/accounts/:trading_account_id/property_rank" do
        trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id].to_s)
        raise APIErrors::VeriftyFail, "券商帐号不存在" unless trading_account

        datas = Investment.property_rank(trading_account.id)
        present [follow_compare: datas]
      end

      add_desc "比一比chart数据（最后一刻的数据就是顶部显示的内容）"
      params do
        requires :date, type: String, desc: "开始日期，例如：2014-10-10"
      end
      get "/accounts/:trading_account_id/property_chart" do
        trading_account = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id].to_s)
        raise APIErrors::VeriftyFail, "券商帐号不存在" unless trading_account

        net_return_percent = UserDayProperty.net_return_percent(trading_account, params[:date])

        if net_return_percent[0]
          start_date = Time.at(net_return_percent[0][:date]/1000).strftime("%Y-%m-%d")
          stock_id = trading_account.is_a?(TradingAccountPassword) ? BaseStock.sse.id : BaseStock.sp500.id
          index_name = trading_account.is_a?(TradingAccountPassword) ? "sh" : "bp"
          json_data = RestClient.api.stock.bar(stock_id, start_date: start_date, end_date: Date.today, precision: 'days')
          if json_data[0]
            total_value = json_data[0][1]
            index_percent = json_data.map { |item| {date: item[0], value: item[1].fdiv(total_value) - 1.0} }
            net_dates, index_dates = net_return_percent.map{|x|x[:date]}, index_percent.map{|x| x[:date]}
            datas = {
              net_return_percent: net_return_percent.select{|x| index_dates.include?(x[:date])},
              index_percent: index_percent.select{|x| net_dates.include?(x[:date])},
              index_name: index_name
            }
          else
            datas = []
          end
        else
          datas = []
        end

        present datas
      end

      add_desc "同步某券商帐号的持仓到自选"
      params do
        requires :trading_account_ids, desc: "多个ids用,间隔", type: String
      end
      post "/accounts/sync_follow" do

        raise APIErrors::VeriftyFail, "trading_account_ids 不存在" unless params[:trading_account_ids].present?
        raise APIErrors::VeriftyFail, "trading_account_ids 格式不正确" unless params[:trading_account_ids] =~ /^(\d+,?)+$/

        params[:trading_account_ids].split(",").each do |id|
          trading_account.sync_follow if trading_account = TradingAccount.find_with_pretty_id(current_user.id, id)
        end
      end

      add_desc "验证券商帐号登录状态"
      get "/accounts/:trading_account_id/check_login" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
        present ta.logined?
      end

      add_desc "券商帐号登录"
      params do
        optional :password, desc: "密码", type: String
        optional :safety_info, desc: "通讯密码", type: String
      end
      post "/accounts/:trading_account_id/login" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
        msg = RestClient.trading.account.login(ta, params[:password], params[:safety_info]).errors.messages
        raise APIErrors::VeriftyFail, msg unless msg.blank?
      end

      add_desc "委托下单", entity: ::Entities::Order
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
        requires :stock_id, desc: "股票ID", type: Integer
        requires :prop, desc: "委托类型", type: String, values: BaseStock.order_type_keys
        requires :bs, desc: "买卖方向", type: String, values: ["buy", "sell"]
        requires :price, desc: "委托价格", type: Float
        requires :amount, desc: "委托数量", type: Integer
      end
      post "/accounts/:trading_account_id/orders" do

        trade_type =
          case params[:bs]
          when "buy"
            "OrderBuy"
          when "sell"
            "OrderSell"
          end

        order_params = {
          trading_account_id: params[:trading_account_id],
          order_details_attributes: {
            "0" => {
              base_stock_id: params[:stock_id],
              est_shares: params[:amount],
              order_type: params[:prop],
              limit_price: params[:price]
            }
          }
        }.with_indifferent_access

        result = OrderCreate.new(current_user, trade_type, order_params).call

        if result.has_key?(:login) && !result[:login]
          raise ::APIErrors::AccountNotlogin, "帐号还未登录"
        else
          #raise ::APIErrors::VeriftyFail, "下单失败"
          raise ::APIErrors::VeriftyFail, result[:error_msg]
        end if result[:error]

        order = current_user.orders.unconfirmed.find(result[:order_id])
        order.present? && order.confirm_by_user

        present order, with: ::Entities::Order
      end

      add_desc "委托撤单", entity: ::Entities::Order
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
        requires :order_id, desc: "订单ID", type: Integer
      end
      delete "/accounts/:trading_account_id/orders" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])

        order = ta.stock_orders.find(params[:order_id])

        # 撤单
        order.cancel_by_user rescue raise ::APIErrors::VeriftyFail, "撤单失败"

        present order, with: ::Entities::Order
      end

      add_desc "所有券商帐号的委托订单列表", entity: ::Entities::Order
      params do
        optional :all, using: ::Entities::Paginate.documentation
        optional :bs, desc: "买卖方向", type: String, values: ["buy", "sell"]
        optional :status, desc: "订单状态(多个请用,隔开) #{Order::STATUS.keys.map(&:to_s).join(" ")}", type: String
        optional :base_stock_ids, desc: "股票ids(多个请用,隔开)", type: String
      end
      get "/accounts/orders/all" do
        orders = Order.where(trading_account_id: TradingAccount.published.by_user(current_user.id).pluck(:id))

        orders = orders.send(params[:bs].to_sym) if params[:bs].present?

        orders = orders.where(status: params[:status].split(",")) if params[:status].present?

        orders = orders.where(id: OrderDetail.where(base_stock_id: params[:base_stock_ids].split(",")).pluck(:order_id).uniq) if params[:base_stock_ids].present?

        orders = orders.order("updated_at desc")

        present paginate(orders.includes(:order_details)), with: ::Entities::Order
      end

      add_desc "某券商帐号下委托订单列表", entity: ::Entities::Order
      params do
        optional :all, using: ::Entities::Paginate.documentation
        requires :trading_account_id, desc: "券商账户ID", type: String
        optional :bs, desc: "买卖方向", type: String, values: ["buy", "sell"]
        optional :status, desc: "订单状态(多个请用,隔开) #{Order::STATUS.keys.map(&:to_s).join(" ")}", type: String
        optional :base_stock_ids, desc: "股票ids(多个请用,隔开)", type: String
      end
      get "/accounts/:trading_account_id/orders" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])

        orders = ta.stock_orders

        orders = orders.send(params[:bs].to_sym) if params[:bs].present?

        orders = orders.where(status: params[:status].split(",")) if params[:status].present?

        orders = orders.where(id: OrderDetail.where(base_stock_id: params[:base_stock_ids].split(",")).pluck(:order_id).uniq) if params[:base_stock_ids].present?

        orders = orders.order("updated_at desc")

        present paginate(orders.includes(:order_details)), with: ::Entities::Order
      end

      add_desc "刷新券商信息"
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
      end
      get "/accounts/:trading_account_id/refresh" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])

        present ta.try(:refresh_cash)
      end

      add_desc "券商账户对比大盘（真实账户只支持当天对比）"
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
        requires :type, desc: "查询日期类型", type: String, values: %w[day month year total]
      end
      get "/accounts/:trading_account_id/contrast" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
        present ta.sim_contrast(params[:type])
      end

      add_desc "风险评估  level 1 => 高风险 3 => 中风险 5 => 低风险"
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
      end
      get "/accounts/:trading_account_id/position_risk" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])
        present AccountPositionRisk.risk_result_for(ta.id)
      end

      add_desc "股票交易详情 bids: 买5价格 offers: 卖5价格 realtime_price: 市价 board_lot: 手 position: 可卖数量 order_types: 订单类型"
      params do
        requires :trading_account_id, desc: "券商账户ID", type: String
        requires :stock_id, desc: "股票ID", type: Integer
      end
      get "/accounts/:trading_account_id/stocks" do
        ta = TradingAccount.find_with_pretty_id(current_user.id, params[:trading_account_id])

        stock = BaseStock.find(params[:stock_id])

        result = {
          bids: stock.bids,
          offers: stock.offers,
          realtime_price: stock.realtime_price.try(:to_f) || 0,
          board_lot: stock.try(:board_lot) || 1,
          position: ta.can_selled_shares_of(stock.id),
          order_types: ta.order_types_by(stock).map{|k,v| {title: v.to_s, value: k.to_s} }
        }

        present result
      end

    end
  end
end
