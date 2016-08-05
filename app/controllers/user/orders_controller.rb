class User::OrdersController < User::BaseController
  before_action :set_menu, only: [:index]
  before_action :find_order, only: [:details]

  def index
    params[:q] ||= {}
    params[:q][:page] = params[:page]
    params[:q][:account] ||= params[:account_id]
    @search = OrderSearch.new(current_user, params[:q])
    redirect_to accounts_path and return if @search.accounts.blank?
    
    @in_progress_orders = @search.processing_orders
    @history_orders = @search.history_orders
  end

  def details
    @order_details = @order.order_details.includes(:stock)
  end

  private
  def set_menu
    @page_title = "订单管理"

    @sub_menu_tab = 'orders'
    @top_menu_tab = "positions"
  end

  def find_order
    @order = Order.find(params[:id])
  end
end