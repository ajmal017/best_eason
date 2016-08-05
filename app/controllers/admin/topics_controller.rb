class Admin::TopicsController < Admin::ApplicationController
  # before_action :set_topic, only: [:show, :edit, :update, :destroy, :save_img, :crop_pic, :add_stock, :update_baskets, :toggle_visible]
  before_action :set_topic, except: [:index, :new, :create, :positions]
  
  def index
    params[:q].transform_values!{|v| v.try(:strip)} if params[:q]
    @q = Topic.search(params[:q])
    @topics = @q.result.includes(:author).sort.paginate(page: params[:page]||1, per_page: Topic::ADMIN_PER_PAGE)
    @topics = @topics.where(market: params[:market]) if params[:market].present?

    @can_not_sorted = params[:market].present? || (params[:q] && params[:q][:title_cont].present?)
  end

  def show
  end

  def new
    @topic = Topic.new(template: Topic::TEMPLATES.keys.first)
  end

  def edit
  end

  def create
    @topic = Topic.new(topic_params.merge(author_id: current_admin_staffer.id))

    respond_to do |format|
      if @topic.save
        format.html { redirect_to [:admin, @topic], notice: '热点已创建，请完善后面信息！' }
        format.json { render json: {status: true, topic_id: @topic.id} }
      else
        format.html { render :new }
        format.json { render json: {status: false} }
      end
    end
  end

  def update
    respond_to do |format|
      if @topic.update(topic_params)
        format.html { redirect_to [:admin, @topic], notice: '修改成功！' }
        format.json  { render json: {status: true, topic_id: @topic.id} }
      else
        format.html { render :edit }
        format.json  { render json: {status: false} }
      end
    end
  end

  def destroy
    @topic.destroy
    redirect_to admin_topics_url, notice: '删除成功！'
  end

  def save_img
    if @topic.temp_image
      @topic.temp_image.update(image: params[:topic][:img])
    elsif @topic
      @topic.create_temp_image(image: params[:topic][:img])
    end
  end

  def crop_pic
    @topic.crop_temp_image(crop_params)
  end

  def save_big_img
    if @topic.temp_big_image
      @topic.temp_big_image.update(image: params[:topic][:img])
    elsif @topic
      @topic.create_temp_big_image(image: params[:topic][:img])
    end
  end

  def crop_big_pic
    @topic.crop_temp_big_image(crop_params)
  end

  def add_stock
    @stock = BaseStock.find(params[:stock_id])
    if @topic.market == @stock.market_area.to_s
      if @topic.stocks.exists?(@stock)
        @topic_stock = @topic.topic_stocks.float.where(base_stock_id: @stock.id).first
        @topic_stock.update(fixed: true) if @topic_stock
      else
        @topic_stock = @topic.topic_stocks.fixed.create(base_stock_id: @stock.id)
      end
    end
  end

  def update_baskets
    @topic.update(basket_ids: params[:basket_ids].try(:join, ","))
    render text: "ok"
  end

  def positions
    ids = params[:ids].map(&:to_i)
    if params[:class_name] == "Topic"
      ids = Topic.sort.limit((params[:page].to_i-1)*Topic::ADMIN_PER_PAGE).select(:id).map(&:id) + ids if params[:page].to_i>1
      ids = ids + Topic.sort.select(:id).map(&:id)
    end
    Topic.update_positions(params[:class_name], ids.uniq)
    render json: {status: true}
  end

  def toggle_visible
    @topic.toggle!(:visible)
    render json: {visible: @topic.visible}
  end

  def baskets
    baskets_pool = Topic.baskets_from_pool(params[:id])
    datas = baskets_pool.map{|b| b.basket.blank? ? nil : {id: b.basket_id, title: b.basket.try(:title), author: b.basket.try(:author).try(:username), count: b.total_count, created_at: b.basket.created_at.to_s(:db)}}
    render json: datas.compact
  end

  def pre_stocks
  end

  def pool
    @fixed_pool = @topic.topic_stocks.fixed.includes(:base_stock).to_a
    @float_pool = [] #@topic.topic_stocks.float.includes(:base_stock).to_a
  end

  # 浮动股票池
  def pending_pool
    @data = Topic.pending_float_stock_pool(params[:id])
  end

  def adjust_basket
    @topic.convert_to_basket(true)
    render json: {status: true}
  end

  def move_top
    @topic.update(position: -1)
    render text: "ok"
  end

  def reset_articles
    @topic.reset_articles
  end

  private
  
  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:title, :sub_title, :market, :summary, :notes, :template)
  end

  def crop_params
    params.require(:topic).permit(:crop_x, :crop_y, :crop_w, :crop_h)
  end
end
