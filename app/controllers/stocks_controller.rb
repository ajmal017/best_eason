class StocksController < ApplicationController
  #before_filter :authenticate_user!, only: [:show]
  before_action :require_stock_bar, only: [:index]
  before_action :find_stock, only: [:show, :trade]
  after_action :send_to_publish_stock_ids_set, only: [:show]
  
  before_action :set_menu
  layout 'application'
  
  def index
    set_mobile_link("/stocks")
    @market_indexes = ::StockIndex.all
    @market_index_infos = BaseStock.market_index_infos
    @recommend = BaseStock.recommend_by_cache
    @search = params[:search] || {}
    @sort = params[:sort] || {}
    @stocks = BaseStock.search_list(@search.dup).order(sort_by + " " + direction).paginate(page: params[:page] || 1,  per_page: params[:per_page] || 15) unless @search.blank?
  end
  
  def search
    @stocks = BaseStock.search_list(search_params).order(sort_by + " " + direction).paginate(page: params[:page] || 1,  per_page: params[:per_page] || 15)
    @refresh = params[:refresh] == "true"
    @scroll = params[:scroll] == "true"
  end

  def show
    @stock_screener = @stock.stock_screener
    @currency_unit = @stock.currency_unit
    @already_follow = @stock.followed_by_user?(current_user.try(:id))
    @is_index = @stock.is_index?
    if @is_index
      @top_up_stocks = @stock.top_stocks_by_exchange("desc")
      @top_down_stocks = @stock.top_stocks_by_exchange("asc")
    else
      @topic_stocks = TopicStock.fixed.visible.where(base_stock_id: @stock.id).order(id: :desc).limit(4).includes(:topic)
      @relevant_baskets = @stock.relevant_baskets
    end
    
    set_mobile_link("/stocks/#{@stock.id}")
    add_publisher_events('stock_realtime_infos')
    gon.stock_id = @stock.id
    gon.account_id = params[:account_id];
  end

  def trade
    @trading_accounts = TradingAccount.accounts_by(current_user.try(:id), @stock.market_area, false, true)
    selected_account = params[:account_id] || cookies['last_selected_account']
    @trading_account = @trading_accounts.select{|a| a.pretty_id == selected_account}.first || @trading_accounts.first
    cookies['last_selected_account'] = @trading_account.pretty_id if @trading_account
  end

  private
  def find_stock
    @stock = BaseStock.find(params[:id])
  end
  
  def search_params
    params.require(:search).permit(:market_region, :sector, :style, :opinion, :trend, :consideration, :capitalization, :score) rescue {}
  end
  
  def sort_by
    params[:sort] && %w{market_value score change_rate}.include?(params[:sort][:sort_by]) ? params[:sort][:sort_by] : 'market_value'
  end
  
  def direction
    params[:sort] && %w{desc asc}.include?(params[:sort][:direction]) ? params[:sort][:direction] : 'desc'
  end

  def set_menu
    @top_menu_tab = 'stock'
  end

  def send_to_publish_stock_ids_set
    PublishStockId.add_by_stock(@stock)
  end
end
