class Admin::BasketsController < Admin::ApplicationController
  before_action :find_basket, except: [:index, :related_baskets, :stocks_data]

  def index
    @page_title = "组合投资列表"
    params[:q] ||= {}
    @q = Basket.normal.includes(:author).search(params[:q])
    order = params[:q][:basket_adjustments_id_not_null].blank? ? 'created_at desc' : 'basket_adjustments.created_at desc'
    @baskets = @q.result.order(order).paginate(page: params[:page] || 1, per_page: 20).to_a
  end
  
  def recommend
    @status = @basket.recommend!
  end
  
  def discommend
    @status = @basket.discommend!
  end

  def cover
  end

  def hide
    @basket.update(visible: !@basket.visible)
    render nothing: true
  end

  def audit
    @basket_audits = @basket.basket_audits.includes(:admin).order(id: :desc)
  end

  def audit_pass
    status = @basket.audit_pass!(current_admin_staffer)
    render :json => {status: status}
  end

  def audit_not_pass
    status = @basket.audit_not_pass!(params[:reason], current_admin_staffer)
    render :json => {status: status}
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
    @basket.img = @basket.temp_image.image.larger
    @basket.write_img_identifier
    @basket.save
  end

  # 统计股票使用频率
  def stocks_data
    @page_title = "热股分析 Top 20"
    @market = %w{cn us hk}.include?(params[:market]) ? params[:market] : "cn"
    basket_ids = Basket.normal.public_finished.where(market: @market).pluck(:id)
    stock_ids = BaseStock.try(@market).pluck(:id)
    @data = BasketStock.select("stock_id, count(*) as total_count, avg(weight) as avg_weight, group_concat(basket_id) as basket_ids")\
    .where(basket_id: basket_ids, stock_id: stock_ids).where("weight >= 0.1").group(:stock_id).having("total_count > 1").includes(:stock).order("total_count desc").limit(20)
  end

  private
  def find_basket
    @basket = Basket.find(params[:id])
  end
end
