class Ajax::StocksController < Ajax::ApplicationController
  before_filter :authenticate_user!, only: [:unfollow, :follow, :follow_or_unfollow, :save_avatar, :crop_avatar, :setting_crop]
  before_action :find_stock, only: [:infos, :unfollow, :follow, :follow_with_render, :follow_or_unfollow, :quote_prices, :klines, :minutes, :suggest_render, :unsuggest, :rt, :rt_logs, :announcements, :friends_with_followed]
  protect_from_forgery except: [:quote_prices, :klines]

  def search
    search_opts = {limit: (params[:limit] || 5).to_i, search_all: params[:search_all], show_desc: params[:show_desc], market: params[:market]}
    stocks = BaseStock.fuzzy_query(params[:term], search_opts)
    render json: {stocks: stocks, term: params[:term]}
  end

  def query
    stocks = BaseStock.query_by_term(params[:q])
    render json: stocks
  end

  def infos
    stock_notes = BasketStock.find_by(basket_id: params[:basket_id], stock_id: params[:id]).try(:notes).to_s
    infos = {prices_in_52_weeks: @stock.prices_in_52_weeks, latest_price: @stock.realtime_price, symbol: @stock.ticker,
             market_capitalization: @stock.market_capitalization_by_c_unit, pe_ratio: @stock.pe_ratio, com_intro: @stock.com_intro.truncate(300),
             company_name: @stock.com_name, basket_stock_notes: stock_notes, unit: @stock.currency_unit,
             returns: {one_day: @stock.change_percent, one_month: @stock.one_month_return,
                       six_month: @stock.six_month_return, one_year: @stock.one_year_return}
            }
    render :json => infos
  end

  def bubble
    stock = BaseStock.find(params[:id])
    datas = {
      stock: {
        name: stock.truncated_com_name,
        symbol: stock.symbol,
        link: stock_path(stock),
        price: stock.realtime_price_with_unit,
        change: stock.change_from_previous_close.round(2),
        change_percent: stock.change_percent.round(2)
      },
      focused:{
        total: stock.follows_count,
        lists: stock.followers.limit(8).map do |user|
          {link: "/p/#{user.id}", avator: user.avatar_url(:small), title: [user.username, user.headline].compact.join(", ") }
        end
      },
      isFocused: stock.followed_by?(current_user.try(:id)) ? 1 : 0
    }
    render json: datas
  end

  def unfollow
    @stock.unfollow_by_user(current_user.id)
    render :text => "ok"
  end

  def follow
    if @stock.followed_by_user?(current_user.id)
      @follow = @stock.get_follow(current_user.id)
    else
      @follow = @stock.follow_by_user(current_user.id)
    end
    render json: {follow_id: @follow.id}
  end

  def follow_or_unfollow
    result = @stock.follow_or_unfollow_by_user(current_user.id)
    render :json => {followed: result}
  end

  def quote_prices
    prices = RestClient.api.stock.bar(@stock.id, precision: 'weeks')
    six_months = RestClient.api.stock.bar(@stock.id, start_date: 6.months.ago.to_date-3.day, end_date: Date.today, precision: 'days')
    one_day_minutes, week_minutes = ChartLine.cached_minute_prices(@stock)
    render json: {prices: prices, six_months: six_months, one_day_minutes: one_day_minutes, week_minutes: week_minutes}, callback: params[:callback]
  end

  def klines
    case params[:type]
    when "day"
      @kline_datas = Kline.daily_quotes(@stock)
    else
      @kline_datas = RestClient.api.stock.kline(params[:id], params[:type])
    end
    render json: @kline_datas, callback: params[:callback]
  end

  def minutes
    one_day_minutes = ChartLine.one_day_minutes(@stock)
    start_trade_time = @stock.prev_latest_start_time
    end_trade_time = @stock.prev_latest_end_time
    render json: {
      one_day_minutes: one_day_minutes, previous_close: @stock.previous_close.to_f, market: @stock.market_area,
      start_trade_timestamp: (start_trade_time.to_i + start_trade_time.utc_offset) * 1000,
      end_trade_timestamp: (end_trade_time.to_i + end_trade_time.utc_offset) * 1000
    }
  end

  def suggest_render
    suggest_stock = SuggestStock.find(params[:suggest_stock_id])
    @suggest = @stock.suggested_to(suggest_stock)
  end

  def unsuggest
    suggest_stock = SuggestStock.find(params[:suggest_stock_id])
    @stock.unsuggested_to(suggest_stock)
    render text: "ok"
  end

  def save_avatar
    if params[:id].to_i == current_user.id
      if current_user.temp_image
        current_user.temp_image.update(image: params[:user][:avatar])
      else
        current_user.create_temp_image(image: params[:user][:avatar], user_id: current_user.id)
      end
    end
  end

  def crop_avatar
    current_user.temp_image.update(upload_user_params)
  end

  def setting_crop
    @ret = current_user.temp_image.update(upload_user_params)
    current_user.update(avatar: current_user.temp_image.image.large) if @ret
  end

  def chart
    stock = BaseStock.find(params[:id])
    render json: stock.five_day_chart_datas
  end

  # 实时刷新股票实时数据
  def rt
    PublishStockId.add_by_stock(@stock)
    render :nothing => true
  end

  def recommend
    # A股ID待确认9326/10642
    base_stock_ids = [9030,8059,4637,12290,5122,10348,6235,5424,7669]
    @base_stocks = BaseStock.where(id: base_stock_ids).order("field(id,#{base_stock_ids.join(',')})")
  end

  # 个股新闻
  def news
    @news = RestClient.api.stock.spider_news.list(params[:id]) rescue []
  end

  # 公告
  def announcements
    @notices = RestClient.api.stock.announcement.list(params[:id]) rescue []
  end

  def announcement
    @content = RestClient.api.stock.announcement.content(params[:id])
  end

  # 逐笔数据
  def rt_logs
    @rt_logs = RestClient.api.stock.rt_log(params[:id])
  end

  # 个股 - 主力资金 - 板块资金流向
  def trading_flows
    @trading_flows = RestClient.api.stock.trading_flow.find(params[:id])
  end

  # 个股 - 主力资金 - 饼图
  def flow_charts
    @percents = RestClient.api.stock.trading_flow.pie(params[:id])
  end

  def bubble_trading_flows
    @trading_flows = RestClient.api.stock.trading_flow.industry_top10(params[:id])
  end

  def industry_percent_flows
    datas = RestClient.api.stock.trading_flow.left_chart(params[:id])
    render json: datas
  end
  
  def friends_with_followed
    if current_user
      @users = @stock.followers.where(id: current_user.friends.map(&:followable_id))
    else
      @users = []
    end
  end

  def prices
    prices = (params[:stock_ids]||[]).map do |id|
      rs = ::Rs::Stock.find(id)
      [id, rs.realtime_price, rs.price_changed]
    end
    render json: prices
  end

  private
  def find_stock
    @stock = BaseStock.find(params[:id])
  end

  def add_realtime_kline_datas
    if @stock.market_open?
      realtime_data = @stock.realtime_kline_data(params[:type])
      if @kline_datas.last["start_date"] < realtime_data[:start_date]
        @kline_datas.push(realtime_data)
      # else
      #   last_point = @kline_datas.last
      #   last_point["high"] = [last_point["high"], realtime_data[:high]].max
      #   last_point["low"] = [last_point["low"], realtime_data[:low]].min
      #   last_point.merge!("close" => realtime_data[:close], "end_date" => realtime_data[:end_date], "date" => realtime_data[:date])
      end
    end
  end
end
