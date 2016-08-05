class Admin::LandingsController < Admin::ApplicationController
  # load_and_authorize_resource 

  def index
    @page_title = "首页邀请码申请记录"
    @provinces = CityInit.get_provinces[0]
    @q = Landing.created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq]).search(params[:q])
    @landings = @q.result.order("id desc").paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
  

end
