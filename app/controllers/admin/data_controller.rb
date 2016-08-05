class Admin::DataController < Admin::ApplicationController
  def currency
    @page_title = "汇率列表"
    
    @hkd_to_usd = $redis.hgetall("currency:hkd_to_usd")
    @usd_to_hkd = $redis.hgetall("currency:usd_to_hkd")
  end


  def filters
    @page_title = "推荐Filter数据"
  end

  def user_active
    @page_title = "用户活跃度统计"
    @begin_date = Date.parse(params[:begin_date] || Time.now.strftime("%Y-%m-%d"))
    @end_date = Date.parse(params[:end_date] || Time.now.strftime("%Y-%m-%d"))
    @deed = params[:deed] || "or"

    @users = User.where(id: User.active_user_ids_by_date(@begin_date, @end_date, @deed)).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

end
