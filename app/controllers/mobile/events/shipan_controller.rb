class Mobile::Events::ShipanController < Mobile::ApplicationController
  layout 'mobile'

  # before_action :authenticate_user!

  before_action :find_contest, :page_title

  def index
    set_pc_link("/events/shipan")
    @ranks = @contest.search_rank(params[:page] || 1, 10)
    # @page_title = "排行榜"
    render :ranks
  end

  def my
    # @page_title = "我的"
    set_pc_link("/events/shipan")
    render :not_login and return unless user_signed_in?
    
    @rank = @contest.basket_rank_of(current_user.id)
    if @rank
      @basket = @rank.basket
      @user = @basket.author
      position_infos
    else
      @user = current_user
    end
    render :show
  end

  def show
    @basket = Basket.find(params[:id])
    set_pc_link("/baskets/#{@basket.id}")
    @rank = @contest.basket_rank_of(@basket.author_id)
    @user = @basket.author
    position_infos
    # @page_title = "参赛组合"
  end

  def trading
    set_pc_link("/events/shipan/trading")
    @order_details = @contest.latest_order_details(60)
    # @page_title = "动态"
  end

  def ranks
    set_pc_link("/events/shipan/ranks")
    @ranks = @contest.search_rank(params[:page] || 1, 10)
    # @page_title = "排行榜"
  end

  private
  
  def page_title
    @page_title = "财说首届实盘炒股大赛"
  end
  
  def find_contest
    @contest = Contest.find(3)
  end

  def position_infos
    @account = @basket.pt_account
    @last_trade_at = @account.order_details_by(1, 1).first.try(:trade_time)
    @grouped_stock_infos = @account.stocks_infos.group_by{|x| x[:sector_name]}
    @sector_percents = @grouped_stock_infos.map do |sector_name, infos|
      [sector_name, infos.map{|x| x[:single_position].round(2)}.reduce(:+).round(2)]
    end.to_h
    @cash_percent = (100 - (@sector_percents.values.reduce(:+) || 0)).round(2)
  end
end