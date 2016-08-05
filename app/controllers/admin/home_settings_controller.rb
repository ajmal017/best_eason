class Admin::HomeSettingsController < Admin::ApplicationController

  def index
    
  end

  def topic
    @topic = Recommend.topic
  end

  def basket
    @basket = Recommend.basket
  end

  def stock_search
    @stock_search = Recommend.stock_search
  end

  def banners
    @banners = Recommend.banner_url_and_images
  end

  def mobile_banners
    @m_banners = MobileRecommend.banner_url_and_images
  end

  def mobile_p2p_banners
    @m_p2p_banners = MobileP2pRecommend.banner_url_and_images
  end

  def update_topic
    @status = Recommend.set_topic(params[:topic_id])
  end

  def update_basket
    @status = Recommend.set_basket(params[:basket_id])
  end

  def update_stock_search
    @status = Recommend.set_stock_search(params[:search])
  end

  def users
    @user_infos = Recommend.user_infos
  end

  def add_user
    user = User.find(params[:user_id])
    Recommend.add_user(user.id, params[:desc])
    render text: "ok"
  end

  def del_user
    Recommend.del_user(params[:user_id])
    render text: "ok"
  end

  def users_position
    Recommend.set_users_position(params[:user_ids])
    render text: "ok"
  end

  def expire_cache
    expire_fragment("cs:topics_index:right")
    render text: "ok"
  end

  def activities
    @count = $redis.get("virtual_contest_participants_count") || 0
  end

  def contest_count
    $redis.set("virtual_contest_participants_count", params[:count].to_i)
    render nothing: true
  end

  def mobile_ad
  end
end
