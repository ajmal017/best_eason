class Admin::UserBindingsController < Admin::ApplicationController
  def index
    @page_title = "用户调平管理"
    @q = UserBinding.includes(:reconcile_request_list).search(params[:q])
    @user_bindings = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
  
  def update
    @page_title = "用户调平"
    @user_binding = UserBinding.find(params[:id])
    @user_binding.reconcile
    redirect_to admin_user_bindings_path
  end
  
  def edit
    @page_title = "用户调平"
    @user_binding = UserBinding.find(params[:id])
    @symbol = params[:symbol]
  end
  
  def reconcile
    @user_binding = UserBinding.find(params[:id])
    @user_binding.reconcile_by_symbol_and_price(article_params[:symbol], article_params[:price])
    redirect_to admin_user_bindings_path
  end
  
  private
  def article_params
    params.permit(:symbol, :price)
  end
end
