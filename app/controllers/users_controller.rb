class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :profile, :fans, :follows, :feeds] # TODO 是否有用???
  # before_action :set_menu
  #before_action :handle_unopen_trading, only: [:investment, :positions, :orders, :brokers]

  WHITE_USER_IDS = [1002, 1015, 1021, 1006, 1178]

  def profile
  end

  def stocks
    @following_stocks = Follow::Stock.followed_stocks_by(current_user.id)
    @rs_stocks = ::MD::RS::Stock.where(:base_stock_id.in => @following_stocks.map(&:followable_id)).map{|s| [s.base_stock_id, s]}.to_h
    @stock_scores = StockScreener.select(:score, :base_stock_id).where(base_stock_id: @following_stocks.map(&:followable_id))
                                    .map{|s| [s.base_stock_id, s.score]}.to_h
    @usd_rates = Currency.all_to_usd
    @top_menu_tab = "following"
    @sub_menu_tab = 'stocks'
    @background_color = "white"
  end

  def brokers
    @page_title = "交易账号管理"
    @top_menu_tab = "positions"
    @sub_menu_tab = 'broker'

    redirect_to succ_user_brokers_path and return if current_user.has_binding_account? || UserBroker.exists?(user_id: current_user.id, status: UserBroker::STATUS[:new])    
    @user_binding = current_user.user_bindings.first
  end

  private
  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :username, :avatar, :password, :password_confirmation)
  end

  def mark_all_as_read
    @unread_follow_ids = @follower_users.unread.map(&:id)
    current_user.follower_users.unread.update_all(read: true)
  end

  # def set_menu
  #   @top_menu_tab = 'users'
  # end

  # 未开通交易临时处理
  def handle_unopen_trading
    render '/user/brokers/unopen_trading' and return if Rails.env.production? && !WHITE_USER_IDS.include?(current_user.id)
  end
end
