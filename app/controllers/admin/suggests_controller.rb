class Admin::SuggestsController < Admin::ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:update]
  
  def index
    @page_title = "推荐位管理"
    @q = Suggest.includes(:article).order("id asc").search(params[:q])
    @suggests = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
  
  def edit
    @page_title = "修改推荐位"
    @suggest = Suggest.find(params[:id])
  end
  
  def update
    @page_title = "修改推荐位"
    @suggest = Suggest.find(params[:id])
    @suggest.image = suggest_params.delete(:image)
    @suggest.update_attributes(suggest_params)
    @suggest.save!
    expire_fragment('article_index_suggests')
    redirect_to admin_suggests_path
  end

  def pic
    @suggest = Suggest.find(params[:id])
    @article = @suggest.article
  end

  def save_img
    @suggest = Suggest.find(params[:id])
    if @suggest.temp_image
      @suggest.temp_image.update(image: params[:suggest][:img])
    else
      @suggest.create_temp_image(image: params[:suggest][:img])
    end
  end

  def crop_pic
    @suggest = Suggest.find(params[:id])
    @suggest.temp_image.update(params.require(:suggest).permit(:crop_x, :crop_y, :crop_w, :crop_h))
    @suggest.temp_image.save!
    @suggest.image = @suggest.id == 1 ? @suggest.temp_image.image.large : @suggest.temp_image.image.small
    @suggest.write_image_identifier
    @suggest.save!
    expire_fragment('article_index_suggests')
  end
  
  private

  def log_operation
    AdminLog.create(content: params[:controller] + "#" + params[:action], log_type: "article", request_ip: request.ip, staffer_id: current_admin_staffer.id)
  end

  def suggest_params
    params.require(:suggest).permit(:title, :image, :article_id)
  end
  
end
