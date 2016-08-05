class Ajax::FollowStocksController < Ajax::ApplicationController
  before_filter :authenticate_user!
  before_action :find_follow, only: [:update_notes, :destroy, :trade_stock, :tag]

  def update_notes
    status = @follow && @follow.update(notes: params[:notes]) && @follow.valid?
    render json: {status: status.present?}
  end

  def destroy
    @tag = Tag::FollowStock.find_by_id(params[:tag_id])
    if @tag.present?
      @follow.delete_taggings_by(@tag.id)
    else
      @follow && @follow.destroy
    end
    render json: {status: true}
  end

  def update_sort
    Follow::Stock.update_sort(current_user, params[:follow_ids])
    render json: {status: true}
  end

  def trade_stock
    @stock = @follow.followable
    @trading_accounts = TradingAccount.accounts_by(current_user.id, @stock.market_area, false, true)
    selected_account = params[:account_id] || cookies['last_selected_account']
    @trading_account = @trading_accounts.select{|a| a.pretty_id == selected_account}.first || @trading_accounts.first
    cookies['last_selected_account'] = @trading_account.pretty_id if @trading_account
  end

  def tag
    tag = @follow.tag_stock(params[:tag_id])
    stock = @follow.followable
    follow_infos = {follow_id: @follow.id, notes: @follow.notes, followed_price: @follow.price}
    stock_info = stock.attrs_when_follow.merge(follow_infos)
    render json: {status: true, data: stock_info}
  end

  private
  def find_follow
    @follow = Follow::Stock.by_user(current_user.id).find_by_id(params[:id])
  end
end