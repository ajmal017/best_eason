class Events::ShipanController < ApplicationController
  layout 'events'
  before_action :mobile_redirect
  before_action :set_contest, :set_page_title

  def index
    set_mobile_link("/events/shipan")
    @basket_rank = @contest.basket_rank_of(current_user.try(:id))
    @order_details = @contest.latest_order_details(10)
    @ranks = @contest.search_rank(1, 10)
    @basket_most_followed = @contest.basket_most_followed
    @user_most_followed = @contest.user_most_followed
  end

  def trading
    set_mobile_link("/events/trading")
    @order_details = @contest.latest_order_details(params[:limit] || 60, params[:last_id])
    respond_to do |format|
      format.html
      format.json {
        datas = @order_details.map do |od|
          {
            user_id: od.user_id, user_name: od.user.username, basket_id: @contest.basket_id_of(od.user_id),
            id: od.id, trade_action: od.sell? ? "sold" : "bought", stock_id: od.base_stock_id, 
            stock_name: od.stock.com_name, trade_price: od.avg_price, trade_time: od.trade_time.to_s(:only_time)
          }
        end
        render json: {datas: datas}
      }
    end
  end

  def ranks
    set_mobile_link("/events/ranks")
    params[:page] ||= 1
    @ranks = @contest.search_rank(params[:page])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def rules
    set_mobile_link("/events/shipan")
  end

  private

  def set_contest
    @contest = Contest.find(3)
    @header = true
  end

  def set_page_title
    page_title = {index: "首页", trading: "动态", ranks: "排行榜", rules: "大赛明细"}[action_name.to_sym]
    @page_title = page_title.to_s + ' - 财说首届实盘炒股大赛'
  end
end