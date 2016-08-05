class Internal::TradingAccountsController < Internal::BaseController

  def extend_status
    trading_account = TradingAccount.find(params[:id])
    basket_ranks = BasketRank.account_with(trading_account.id)
    basket_ranks.map{|br| br.set_status! }
    render json: {status: true}
  end
end