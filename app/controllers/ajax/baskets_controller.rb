class Ajax::BasketsController < Ajax::ApplicationController
  skip_before_action :require_xhr?, only: [:save_img, :crop_pic, :batch, :contest]
  before_filter :authenticate_user!, only: [:destroy_draft, :save_img, :crop_pic]
  before_action :find_basket, except: [:stocks_pre_index, :search_add, :est_min_money, :fuzzy_query, :infos, :batch, :contest]
  before_action :check_permission, only: [:destroy_draft, :save_img, :crop_pic]

  protect_from_forgery except: [:batch, :contest]

  def screenshot
    Rails.root.join("lib", "phantomjs", "basket.js")

    # Phantomjs.run('my_runner.js', 'hello', 'world')
    render json: { status: 'ok', url: 'http://www.caishuo.com' }
  end

  def fuzzy_query
    baskets = Basket.fuzzy_query(params[:term], 5)
    render json: { baskets: baskets, term: params[:term] }
  end

  def tagged
    tag = ::Tag::Common.find(params[:tag_id])
    tag.add(@basket.original)
    render text: "ok"
  end

  def untagged
    tag = ::Tag::Common.find(params[:tag_id])
    tag.remove(@basket.original)
    render text: "ok"
  end

  def stocks_pre_index
    stocks_indices_for_charts = BasketIndex::Simulate.indices_for_chart(params[:stock_weights], params[:time_period])
    base_stock = BaseStock.where(symbol: params[:stock_weights].try(:keys)).limit(1).first || BaseStock.csi300
    market_name = base_stock.market_index_name
    market_data = base_stock.market_indices_for_charts(params[:time_period])
    render :json => { stocks: stocks_indices_for_charts, market_data: market_data, market_name: market_name }
  end

  # 定制预览
  def baskets_pre_index
    # 判断定制比例是否发生变化
    weights_is_changed = params[:stock_weights].sort.hash != @basket.symbol_weights.map{|symbol, weight|[symbol, weight.to_s]}.sort.hash rescue true

    # 定制后回报(如果没有定制返回[])
    customed_indices = weights_is_changed ? BasketIndex::Simulate.indices_for_chart(params[:stock_weights], params[:time_period]) : []

    # 定制前回报
    start_date = BasketIndex.start_date_by_time_period(params[:time_period])
    original_indices = @basket.original.real_index_changes_for_chart(start_date)

    base_stock = BaseStock.where(symbol: params[:stock_weights].try(:keys).try(:first)).first
    market_name = base_stock.market_index_name
    market_data = base_stock.market_indices_for_charts(params[:time_period])

    render :json => { stocks: customed_indices, market_name: market_name, market_data: market_data, baskets: original_indices }
  end

  # 新页面ajax datas
  def chart_datas
    begin_date = @basket.created_one_year_ago? ? @basket.start_date : 1.years.ago.to_date
    end_date = @basket.exchange_instance.today
    market_name = @basket.market_index_name
    market_data = @basket.market_indices_with_realtime_point(begin_date, end_date)
    basket_real_indices = @basket.real_indices_with_realtime_point(@basket.adjust_start_date, end_date)
    basket_simulated_indices = @basket.created_one_year_ago? ? [] : @basket.simulated_indices_for_chart_cached(begin_date, end_date)
    render :json => { market_name: market_name, market_data: market_data, basket: basket_real_indices, simulated: basket_simulated_indices, 
                      created_timestamp: (@basket.adjust_start_date.to_time+8.hours).to_i * 1000 }
  end

  def save_img
    if @basket.temp_image
      @basket.temp_image.update(image: params[:basket][:img])
    else
      @basket.create_temp_image(image: params[:basket][:img])
    end
  end

  def crop_pic
    @basket.temp_image.update(params.require(:basket).permit(:crop_x, :crop_y, :crop_w, :crop_h))
    @basket.temp_image.save!
  end

  def follow
    follow_result = @basket.follow_or_unfollow_by_user(current_user.id) if user_signed_in?
    followed = user_signed_in? && follow_result
    render :json => { followed: followed }
  end

  def destroy_draft
    @basket.drop!
    render :text => "ok"
  end

  def deploy
    @result = @basket.set_auditing if @basket.can_deploy?
  end

  def archive
    @result = @basket.update(state: Basket::STATE[:archive], archive_date: Date.today) if @basket.completed?
    render json: @result
  end

  def recover
    @result = @basket.update(state: Basket::STATE[:normal], archive_date: nil) if @basket.archived?
    render json: @result
  end

  def comments
    @comments = @basket.comments.includes(:commenter).paginate(page: params[:page] || 1, per_page: Comment::PER_PAGE)

    @commentings = Comment.where(id: @comments.map(&:ary_commentable_ids).flatten.uniq).includes(:commenter).map do |comment|
      [comment.id, comment]
    end.to_h
  end

  def increment_view
    @basket.increment!(:views_count)
    render :nothing => true
  end

  def search_add
    @stock = BaseStock.find_by(symbol: params[:symbol_name])
  end

  def est_min_money
    if params[:symbol_weights].present?
      est_money = Basket.minimum_amount_by(params[:symbol_weights])
      res_money = format("%.2f", est_money.to_f)
    else
      res_money = "--"
    end
    render json: { money: res_money }
  end

  def opinioners
    datas = {}
    latest_opinioners = Opinion.opinioners_by(@basket.id, params[:type])
    datas["avatars"] = latest_opinioners.map {|user| [user.id, user.avatar_url(:small)] }
    if params[:type].blank?
      baskets = Opinion.opinionables_by_opinioners_count('Basket')
      datas["baskets_infos"] = (baskets - [@basket]).map {|b| { id: b.id, title: b.title } }
      datas["opinioners_count"] = Opinion.opinioners_count(@basket.id)
    end
    render json: datas
  end

  def infos
    baskets = Basket.where(id: params[:basket_ids]).includes(:tags)
    search_tag = ::Tag::Common.find_by_id(params[:search_tag])
    tags_data = baskets.map do |b|
      tags = b.display_tags(search_tag).map {|tag| [tag.id, tag.name]}
      [b.id, tags]
    end
    follow_datas = baskets.map {|b| [b.id, b.followed_by_user?(current_user.try(:id))]}
    render json: { tags: tags_data, follows: follow_datas }
  end

  def batch
    baskets = Basket.where(id: params[:basket_ids])
    infos = baskets.map do |basket|
      { id: basket.id, one_month_return: basket.one_month_return.try(:to_f).try(:round, 1),
        total_return: basket.total_return.try(:to_f).try(:round, 1), title: basket.title,
        username: basket.author.try(:username) }
    end
    render json: infos.to_json, callback: params[:callback]
  end

  # A股大赛50强赛数据
  def contest
    ranks = BasketRankCache.top(50)
    baskets = Basket.where(id: ranks.keys).select("baskets.id, baskets.title, users.username").joins(:author).order("field(baskets.id,#{ranks.keys * ','})").to_a
    top_basket = Basket.find(baskets.shift.id)
    top_infos = {
      id: top_basket.id, b_img_url: top_basket.img.url(:large), author_img_url: top_basket.author.try(:avatar).try(:url, :small),
      author: top_basket.author.try(:username), desc: Textable::Base.truncate_long_content(top_basket.description.to_s, 50),
      title: top_basket.title, profit: ranks[top_basket.id.to_s]
    }
    datas = {
      first: top_infos,
      baskets: baskets.map {|b| { id: b.id, author: b.username, profit: ranks[b.id.to_s] } }
    }
    render json: datas, callback: params[:callback]
  end

  private

  def find_basket
    @basket = Basket.find(params[:id])
  end

  def check_permission
    redirect_to baskets_path and return unless @basket.author_id == current_user.id
    redirect_to baskets_path and return if @basket.droped?
  end
end
