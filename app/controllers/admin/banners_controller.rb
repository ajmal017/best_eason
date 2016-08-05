class Admin::BannersController < Admin::ApplicationController
  layout false

  def new
  end

  def create
    banner_upload = Upload::Recommend.find_by_id(params[:upload_banner_id])
    Recommend.add_banner(banner_upload.id, params[:title], params[:banner_url])
    redirect_to banners_admin_home_settings_path, notice: "创建成功"
  end

  def edit
  end

  def update
  end

  def destroy
    banner_upload = Upload::Recommend.find_by_id(params[:id])
    Recommend.delete_banner(banner_upload.id)
    render text: "ok"
  end

  def save_img
    @banner_upload = Upload::Recommend.create(image: params[:image])
  end

  def crop_pic
    @banner_upload = Upload::Recommend.find(params[:upload_recommend_id])
    @banner_upload.update(params.require(:banner).permit(:crop_x, :crop_y, :crop_w, :crop_h))
    @banner_upload.save!
  end

  def update_sort
    Recommend.set_banners_sort(params[:upload_ids])
    render :nothing => true
  end
end
