class Admin::ReconcileRequestListsController < Admin::ApplicationController
  def index
    @page_title = "用户调平管理"
    @q = ReconcileRequestCts.search(params[:q])
    @rrls = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
  
  def update
    @page_title = "用户调平"
    @user_binding = UserBinding.find(params[:id])
    @user_binding.reconcile
    redirect_to admin_user_bindings_path
  end
  
  def edit
    @page_title = "用户调平"
    @account = TradingAccount.find(params[:id])
    @symbol = params[:symbol]
  end
  
  def reconcile
    @account = TradingAccount.find(params[:id])
    @account.reconcile_by_symbol_and_price(article_params[:symbol], article_params[:price])
    redirect_to admin_reconcile_request_lists_path
  end
  
  private
  def article_params
    params.permit(:symbol, :price)
  end
end
