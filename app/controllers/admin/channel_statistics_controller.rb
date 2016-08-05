class Admin::ChannelStatisticsController < Admin::ApplicationController
  respond_to :html, :xls
  def index
    @page_title = "注册渠道统计"
    @pc_app_channel =  params[:pc_app_channel]
    @created_at_gteq =  params[:created_at_gteq]

    @users = User.pc_app_channel(params[:pc_app_channel]).created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq])
    
    select_user = ->(str){
      if str == 'app'
        "users.source = 'app'"
      elsif str == 'pc'
        "users.source is null"
      else
        ""
      end
    }.call(params[:pc_app_channel])
    
    if params[:by_month].blank?
      @user_groups = @users.select("channel_code, count(1) as total_count").group(:channel_code)
      @trading_total_groups = TradingAccount.joins("inner join users on users.id = trading_accounts.user_id")
                                            .select("users.channel_code, count(*) as count")
                                            .where(select_user)
                                            .created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq])
                                            .group(:channel_code)
                                            .order("null")
      #binding.pry
      @trading_normal_groups = TradingAccount.active.joins("inner join users on users.id = trading_accounts.user_id")
                                            .select("users.channel_code, count(*) as count")
                                            .where(select_user)
                                            .created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq])
                                            .group(:channel_code)
                                            .order("null")
      
    else
      @month_groups = @users.select("date_format(created_at, '%Y-%m') as ym, channel_code, count(1) as total_count").group(:ym, :channel_code)
                            .group_by(&:ym).sort_by{|k,v| k}.reverse
      @trading_total_groups = TradingAccount.joins("inner join users on users.id = trading_accounts.user_id")
                                            .select("date_format(trading_accounts.created_at, '%Y-%m') as ym, users.channel_code, count(*) as count")
                                            .where(select_user)
                                            .group(:ym, :channel_code)
                                            .order("null")
                                            .group_by(&:ym).sort_by{|k,v| k}.reverse
      @trading_normal_groups = TradingAccount.active.joins("inner join users on users.id = trading_accounts.user_id")
                                            .select("date_format(trading_accounts.created_at, '%Y-%m') as ym, users.channel_code, count(*) as count")
                                            .where(select_user)
                                            .group(:ym, :channel_code)
                                            .order("null")
                                            .group_by(&:ym).sort_by{|k,v| k}.reverse
    end

    respond_with @user_groups
  end
end
