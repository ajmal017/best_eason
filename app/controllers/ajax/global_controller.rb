class Ajax::GlobalController < Ajax::ApplicationController

  def search
    @keyword = params[:q]
    render json: [] and return if @keyword.blank?
    @keyword = Caishuo::Utils::Translate.cn(@keyword)
    @stocks = BaseStock.fuzzy_query(@keyword, {search_all: true})
    @users = User.search_by(@keyword, 5)
    # render json: {stocks: @stocks, baskets: @baskets}
  end

  def stock_search
    @keyword = params[:q]
    render json: [] and return if @keyword.blank?
    market = params[:market] || "cn"
    @stocks = BaseStock.fuzzy_query(@keyword, {market: market, search_all: true, except_neeq: true})
  end

  def search_user
    users = User.search_by(params[:q], 5).map{|u| u.attributes.slice("id", "username")}
    render json: {users: users, q: params[:q]}
  end

  def search_stock
    stocks = BaseStock.search_by(params[:q], 5).map{|s| s.attributes.slice("id", "name")}
    render json: {stocks: stocks, q: params[:q]}
  end

  # 暂时使用，以后使用market_time接口
  def market_infos
  	area = params[:area] == "hk" ? "hk" : "us"
  	infos = Exchange::Base.by_area(area.to_sym).two_days_trading_status_old
  	render json: infos
  end

  def market_time
    areas = params[:area].blank? ? ["cn", "hk", "us"] : [params[:area]]
    infos = {timestamp: Time.now.to_i}
    areas.each do |area|
      infos[area] = Exchange::Base.by_area(area.to_sym).two_days_trading_status
    end
    render json: infos
  end
end