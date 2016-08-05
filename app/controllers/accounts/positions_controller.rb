class Accounts::PositionsController < Accounts::BaseController
  before_action :load_trading_account

  def index
    @stocks_infos, @total_stocks = @trading_account.stocks_infos_by_page(1)
    @baskets_infos = @trading_account.baskets_infos
    @unllocate_positions = @trading_account.unllocate_positions
    @cash_unit = @trading_account.cash_unit
    @total_cash = @trading_account.total_cash
  end

  def basket_positions
    @stocks_infos = Position.basket_stocks_infos(current_user.id, params[:basket_id], @trading_account)
  end

  def adjust
    redirect_to user_positions_path and return if @trading_account.blank?
    
    @original_basket = Basket.find(params[:basket_id])
    @basket = @original_basket.selled_or_buyed_basket_by(current_user)
    @basket_infos = Position.basket_infos(@original_basket.original.id.to_s, current_user.id, @trading_account)
    @positions = Position.by_basket_and_user(@original_basket.original.id.to_s, current_user.id).includes(:base_stock)

    gon.account_id = @trading_account.pretty_id
  end

  def adjust_add_stock
    @stock = BaseStock.find(params[:stock_id])
  end

  def trade_basket_stock
    @original_basket = Basket.find(params[:original_basket_id])
    @stock = BaseStock.find(params[:stock_id])
    @trade_type = params[:type] == "buy" ? "OrderBuy" : "OrderSell"
    @can_sell_share = current_user.shares_of(@original_basket.id, @stock.id)
    @count_min = params[:type] == "buy" ? @stock.get_board_lot : (@can_sell_share>0 ? @stock.get_board_lot : 0)
    @count_max = params[:type] == "buy" ? 10000000 : (@can_sell_share>0 ? @can_sell_share : 0)
    @input_value = params[:type] == "buy" ? @stock.get_board_lot : (@can_sell_share < @stock.get_board_lot ? @can_sell_share : @stock.get_board_lot)
  end

  def stocks
    @stocks_infos, @total_stocks = @trading_account.stocks_infos_by_page(params[:page])
  end

end