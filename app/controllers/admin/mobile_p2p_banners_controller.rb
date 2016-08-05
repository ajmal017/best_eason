class Admin::MobileP2pBannersController < Admin::ApplicationController
  layout false

  def new
  end

  def create
    banner_upload = Upload::Recommend.find_by_id(params[:upload_banner_id])
    MobileP2pRecommend.add_banner(banner_upload.id, params[:title], params[:banner_type], params[:banner_url])
    redirect_to mobile_p2p_banners_admin_home_settings_path, notice: "创建成功"
  end

  def edit
    banners_info = MobileP2pRecommend.banners
    @banner_upload = Marshal.load(banners_info[params[:id]]).merge(id: params[:id])
  end

  def update
    banner_upload = Upload::Recommend.find_by_id(params[:id])
    MobileP2pRecommend.add_banner(banner_upload.id, params[:title], params[:banner_type], params[:banner_url])
    redirect_to mobile_p2p_banners_admin_home_settings_path, notice: "更新成功"
  end

  def destroy
    banner_upload = Upload::Recommend.find_by_id(params[:id])
    MobileP2pRecommend.delete_banner(banner_upload.id)
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
    MobileP2pRecommend.set_banners_sort(params[:upload_ids])
    render :nothing => true
  end

  def set_ad
    MobileP2pRecommend.set_ad(params[:is_open], params[:version], params[:url], params[:pic])
    render json: {status: "ok"}
  end
end

