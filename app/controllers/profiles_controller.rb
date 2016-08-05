class ProfilesController < ApplicationController
  # before_filter :authenticate_user!, only: [:show]
  before_action :find_user
  before_action :redirect_when_not_xhr?, except: [:show]
  before_action :set_render_type, only: [:show, :followed_baskets, :baskets, :followed_stocks]
  before_action :statistics, only: [:show]
  
  def show
    @baskets = @user.baskets.normal.finished.includes(:latest_basket_index).order("id desc").paginate(page: 1, per_page: 5)
    @stock_follows = Follow::Stock.followed_stocks_by(@user.id).paginate(page:1, per_page: 10)
    @followed_stocks = @stock_follows.map{|f| [f, f.followable]}
    if current_user && @user.id != current_user.try(:id)
      both_uids = Follow::User.both_followed_user_ids(@user, current_user)
      @both_followed_count = both_uids.count
      @both_followed_users = User.where(id: both_uids).order(:id).limit(6)
    end
    # @basket_rank = BasketRank.by_user(@user.id).by_contest(3).last
  end
  
  def baskets
    @baskets = @user.baskets.normal.finished.includes(:latest_basket_index).where("id<?", params[:last_id]).order("id desc")
  end

  def followed_baskets
    @follows = Follow::Basket.followed_baskets_by(@user.id)
    @follows = params[:bids] ? @follows.where.not(followable_id: params[:bids]) : @follows.paginate(page: 1, per_page: 10)
    @followed_baskets = @follows.map(&:followable)
  end

  def followed_stocks
    @followed_stocks = Follow::Stock.followed_stocks_by(@user.id).where.not(followable_id: params[:sids]).map{|f| [f, f.followable]}
  end

  def followed_users
    @followed_users = @user.followed_users.paginate(page: params[:page] || 1, per_page: 10)
  end

  def followers
    @followers = @user.followers.paginate(page: params[:page] || 1, per_page: 10)
  end

  def both_followed
    both_followed_uids = Follow::User.both_followed_user_ids(@user, current_user)
    @users = User.where(id: both_followed_uids).order(:id)
  end

  def toggle_follow
    current_user.follow_user(@user)
  end

  def feeds
    opts = {feeder_id: @user.id, per_page: 11}
    opts[:last_id] = params[:last_id] if params[:last_id].present?
    feeds = MD::Feed.profile.search_feeds_for(nil, opts).to_a
    showed_feeds = feeds.first(10).map(&:web_json)
    nextstart = feeds.size <= 10 ? 0 : showed_feeds.last[:id]
    render json: {lists: showed_feeds, nextstart: nextstart}
  end

  def switch_follow
    @bubble = params[:bubble].present?
    current_user.follow_user(@user)
    # @user.followed_by?(current_user) ? current_user.followed_users.destroy(@user) : current_user.followed_users << @user
  end
  
  private
  def find_user
    @user = params[:id].present? ? User.find(params[:id]) : current_user
    redirect_to login_path and return unless @user
  end

  def redirect_when_not_xhr?
    redirect_to profile_path(@user.id) and return unless request.xhr?
  end
  
  def set_render_type
    @is_self = @user.id == current_user.try(:id)
    @render_type = @is_self ? "self" : "other"
  end
  
  def statistics
    @followed_users_count = @user.pretty_followings_count
    @followers_count = @user.pretty_fans_count
    @abilities = @user.profile.try(:tags) || []
    @total_return = @user.basket_total_return
    @focus = @user.focus_with_color
    @fluctuation = @user.profile_fluctuation
    headline = @user.headline.present? ? @user.username + " - " + @user.headline : @user.username
    @page_title = @user.id == current_user.try(:id) ? '个人主页' : headline
  end
end
