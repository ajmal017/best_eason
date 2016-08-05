class BasketsController < ApplicationController
  before_filter :authenticate_user!, except: [:index, :search, :comment, :show_review, :show]
  before_action :load_basket, only: [:show, :update_title, :add, :base, :info, :update_stocks, :update_stocks_reason, :comment, :show_review, :update_attrs, :custom, :customize, :adjust_logs]
  before_action :show_newest_version, only: [:show]
  before_action :check_common_permission, only: [:add, :base, :info, :update_stocks, :update_stocks_reason, :update_title, :update_attrs]
  before_action :check_special_permission, only: [:add, :update_stocks]
  before_action :check_visible, only: [:show]
  before_action :check_can_customize, only: [:custom, :customize]
  before_action :check_can_adjust_basket, only: [:add]

  before_action :adjust_search_params, only: [:index]
  before_action :set_menu
  before_action :set_list_attrs, only: [:index]

  def index
    @search = params[:search] || {}
    params[:page] = params[:page].to_i <= 0 ? 1 : params[:page]
    @search.reverse_merge!(order: "1m_return", market: "all").merge!(page: params[:page])

    @baskets_results = BasketSearch.exec(@search)
    @baskets = @baskets_results.records.includes(:author).to_a

    if request.xhr?
      @refresh = params[:refresh] == "true"
    else
      @tags = ::Tag::Common.hot_tags_with(@search[:tag])
    end
  end

  def my
    @baskets = current_user.baskets.includes(:author).normal.not_archived.order("id desc").paginate(:page => params[:page] || 1, :per_page => 4)
    @sub_menu_tab = "my"
    @page_title = "我创建的组合"
  end

  def new
    @basket = current_user.baskets.normal.not_finished.order(:id).last || Basket::Normal.create(author_id: current_user.id)

    come_from = "new"
    redirect_to add_basket_path(@basket, {stock_ids: params[:stock_ids], come_from: come_from})
  end

  def add
    @basket_stock_infos = @basket.stock_infos_for_edit
    @exist_stock_ids = @basket_stock_infos.map{|x| x["stock_id"]}
    add_stocks_by_stock_ids if params[:stock_ids].present?
    @basket_stock_infos = @basket_stock_infos.map{|infos| stock_infos_to_front_format(infos)}
    
    @contest_basket = current_user.contest_basket
  end

  def base
    @basket_stocks = @basket.basket_stocks.includes(:stock)
    basket_stocks_grouped_infos
  end

  def info
  end

  def search_add
    @stock = BaseStock.find_by(symbol: params[:symbol_name])
    render json: stock_infos_to_front_format(@stock.basic_infos.merge("weight" => 0))
  end

  def create
  end

  def update_stocks
    status = BasketUpdateStocks.new(@basket, basket_stocks_params).call
    render json: {status: status}
  end

  def update_stocks_reason
    if @basket.update_stocks_step_two(basket_params)
      redirect_to info_basket_path(@basket)
    else
      @basket_stocks = @basket.basket_stocks
      basket_stocks_grouped_infos
      render :action => :base
    end
  end

  def update_title
    @status = @basket.update_stocks_step_three(basket_params)
    @basket.set_auditing if @status
  end

  # 点上一步，暂存用户填写的信息
  def update_attrs
    @basket.update(basket_params)
    if params[:step] == "2"
      redirect_to add_basket_path(@basket)
    else
      @redirect_url = base_basket_path(@basket)
    end
  end

  def show
    @origin_basket = @basket.is_costomized? ? @basket : @basket.original
    @tags = @basket.original.tags.normal.limit(3)
    @is_followed = @basket.followed_by_user?(current_user.try(:id))

    if @basket.shipan?
      set_mobile_link("/events/shipan/#{@basket.id}")
      render_basket_contest
    else
      set_mobile_link("/baskets/#{@basket.id}")
      render_basket_common
    end
  end

  def comment
    #@comment = @basket.comments.create(comment_params.merge(:user_id => current_user.id)) if user_signed_in?
    @comment = Comment.add(current_user.id, comment_params[:content], @basket)
  end

  def show_review
    @comments = @basket.comments.order("id desc").limit(Comment::PER_PAGE)
    if params[:comment_id].present? && !@comments.map(&:id).include?(params[:comment_id].to_i)
      @comments = @basket.comments.where("id >= ?", params[:comment_id]).order("id desc")
    end
  end

  # def custom
  #   @stock_weights = @basket.stock_weights
  # end

  # def customize
  #   @basket = Basket::Custom.create_from(current_user.id, @basket, basket_stocks_params)
    
  #   redirect_to basket_path(@basket)
  # end

  def adjust_logs
    @adjustments = BasketAdjustment.logs(@basket.original_id)
  end

  private

  def render_basket_contest
    @contest = Contest.find(3)
    @basket_rank = @contest.basket_rank_of(@basket.author_id)
    @account = @basket.pt_account
    @top_5_ranks = @contest.search_rank(1, 5)
    @grouped_stock_infos = @account.stocks_infos.group_by{|x| x[:sector_name]}
    @sector_percents = @grouped_stock_infos.map do |sector_name, infos|
      [sector_name, infos.map{|x| x[:single_position].round(2)}.reduce(:+).round(2)]
    end.to_h
    @cash_percent = (100 - (@sector_percents.values.reduce(:+) || 0)).round(2)
    render :show_contest
  end

  def render_basket_common
    @basket_stocks = @basket.basket_stocks.includes(:stock)
    basket_stocks_grouped_infos
    @realtime_index = @basket.realtime_index
    @realtime_change_percent = @basket.change_percent
    render :show
  end

  def basket_stocks_grouped_infos
    @grouped_basket_stocks = @basket_stocks.group_by{|bs| bs.stock.try(:sector_name)}
    @sector_percents = @grouped_basket_stocks.map do |sector_name, basket_stocks|
      [sector_name, basket_stocks.map{|bs| bs.weight_percent}.reduce(:+)]
    end.to_h
    @cash_percent = 100 - (@sector_percents.values.reduce(:+) || 0)
  end

  def basket_stocks_params
    params.require(:basket).permit(basket_stocks_attributes: [:id, :stock_id, :weight, :notes])
  end

  def basket_params
    params.require(:basket).permit(:title, :description, :category, :img, :copy_upload_temp_picture, :is_event, basket_stocks_attributes: [:id, :notes])
  end

  def check_common_permission
    redirect_to baskets_path and return unless @basket.author_id == current_user.id
    redirect_to baskets_path and return if @basket.droped?
  end

  # 目前第一步只有一定条件的才能编辑
  def check_special_permission
    redirect_to baskets_path and return if !@basket.can_edit?
  end

  def load_basket
    @basket = Basket.find(params[:id])
  end

  def show_newest_version
    #访问历史版本时，自动跳转到最新版本
    redirect_to basket_path(@basket.newest_version) and return if !@basket.is_costomized? && @basket.is_history?
  end

  def check_visible
    if !(@basket.completed? || @basket.archived?)
      redirect_to baskets_path and return
    end
  end

  def check_can_customize
    if @basket.has_positions_by?(current_user.id)
      redirect_to adjust_basket_users_path(@basket.original_id) and return
    elsif @basket.costomized_by?(current_user.id)
      costomized_basket = @basket.costomized_basket(current_user.id)
      redirect_to custom_basket_path(costomized_basket) and return if costomized_basket.id != @basket.id
    end

    redirect_to basket_path(@basket) and return if !@basket.is_costomized? && @basket.owned_by?(current_user.id)
  end

  def check_can_adjust_basket
    unless @basket.now_can_edit?
      redirect_to tip_basket_path(@basket) and return
    end
  end

  def comment_params
    params.require(:comment).permit([:content, :bullish])
  end

  def adjust_search_params
    unless request.xhr?
      @keyword = params[:q]
      redirect_to "/baskets?search[search_word]=#{URI.encode(@keyword)}" and return if @keyword.present?
      # @market = params[:market]
      # @market = "all" if @market.blank? # keyword 和 market同时为空
    end
  end

  def set_menu
    @top_menu_tab = 'baskets'
  end

  def set_list_attrs
    unless request.xhr?
      @page_title = "组合列表"
      if params[:search] && params[:search][:market]== "contest"
        @sub_menu_tab = "contest"
      else
        @sub_menu_tab = "all"
      end
    end
  end

  def add_stocks_by_stock_ids
    added_stocks = BaseStock.where(id: params[:stock_ids]).to_a
    market_area = @basket_stock_infos.first.try(:[], "market_area") || added_stocks.first.try(:market_area)
    added_stocks.reject!{|stock| stock.market_area != market_area || @exist_stock_ids.include?(stock.id)}
    added_stocks = @exist_stock_ids.count>9 ? [] : added_stocks[0..( 9 - @exist_stock_ids.count )]
    @basket_stock_infos += added_stocks.map{|s| s.basic_infos}
  end

  def stock_infos_to_front_format(infos)
    keys_map = {truncated_com_name: 'sname', stock_id: 'sid', realtime_price: 'price', 
      change_percent: 'percent', one_year_return: 'year_gain_percent', symbol: 'symbol', 
      adj_pe_ratio: 'pe_value', adj_market_capitalization: 'market_value', weight: 'weight', 
      market_area: 'market', sector_name: 'sector', basket_stock_id: 'basket_stock_id', 
      get_board_lot: 'board_lot', market_state: 'marketstate', min_weight: 'minweight'}
    infos.transform_keys{|k| keys_map[k.to_sym]}
  end

end
