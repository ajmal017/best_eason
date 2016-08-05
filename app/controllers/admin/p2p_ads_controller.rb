class Admin::P2pAdsController < Admin::ApplicationController
  def index
    @page_title = "炒股宝广告位"
    @p2p_ads = P2pAd.all
  end

  def update_all
    params[:p2p_ads].each do |p|
      P2pAd.new(p).save
    end
    redirect_to "/admin/p2p_ads"
  end

  def edit_all
    @page_title = "修改炒股宝广告位"
    @p2p_ads = P2pAd.all
  end

end
