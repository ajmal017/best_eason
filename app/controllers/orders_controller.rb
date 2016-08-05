class OrdersController < ApplicationController
  before_filter :authenticate_user!

  def new
    @original_basket = Basket.find(params[:basket_id])
    redirect_to basket_path(@original_basket) and return unless @original_basket.basket_stocks.first.try(:stock).try(:can_trade?)

    @basket = @original_basket.selled_or_buyed_basket_by(current_user)
    @trading_accounts = TradingAccount.accounts_by(current_user.id, @original_basket.market)
    redirect_to accounts_path and return if @trading_accounts.blank?

    @trading_account = @trading_accounts.select{|a| a.pretty_id == params[:account_id]}.first || @trading_accounts.first
    @user_total_cash = @trading_account.total_cash
    @total_cash_of_basket_currency = @trading_account.total_cash_with_currency(@original_basket.base_currency)
    @basket_minimum_amount = @basket.minimum_amount.round(2)

    @order_details = @basket.est_order_details_attributes
    @order = OrderBuy.new(basket_id: @basket.order_basket_id, basket_mount: 1)
    
    @page_title = "购买投资组合"
  end

  def create
    result = OrderCreate.new(current_user, params[:trade_type], order_params, adjust_stocks_param).call
    render :json => result
  end

  def show
    @order = current_user.orders.unconfirmed.find(params[:id])
    @page_title = "订单确认"
    @background_color = "white"
  end

  def confirm
    @order = current_user.orders.unconfirmed.find(params[:id])
    if @order
      if @order.may_confirm?
        @order.valid_trade
        if @order.errors.empty?
          @order.confirm_by_user
          @ret = {error: false}
        else
          @ret = { error: true, error_msg: @order.errors.messages.values.join("; ") }
        end
      else
        @ret = { error: true, error_msg: "订单已确认过！"}
      end
    end
  end

  def sell
    @basket = Basket.find(params[:basket_id])
    @basket_currency_unit = @basket.currency_unit
    @selled_basket = @basket.selled_or_buyed_basket_by(current_user)

    @trading_accounts = TradingAccount.accounts_by(current_user.id, @selled_basket.market)
    @trading_account = @trading_accounts.select{|a| a.pretty_id == params[:account_id]}.first || @trading_accounts.first
    
    @positions = Position.by_basket_and_user(@basket.id, current_user.id).account_with(@trading_account.id).includes(:base_stock)
    @total_value = @positions.map{|p| p.can_selled_shares * p.base_stock.realtime_price}.sum.to_f
  end

  private
  def order_params
    params.require(:order).permit(:gtd, :basket_mount, :basket_id, :trading_account_id, order_details_attributes: [:base_stock_id, :est_shares, :order_type, :limit_price]).merge(:domain => request.domain)
  end

  def adjust_stocks_param
    {adjust_stocks: params[:adjust_stocks], original_basket_id: params[:original_basket_id]}
  end

end
